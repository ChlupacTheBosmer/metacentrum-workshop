#!/usr/bin/env bash
# Run before every commit and before publishing the repo.
#   ./tools/check_secrets.sh
# Exits non-zero if anything key-shaped is tracked.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0

echo "== 1. files that must never be tracked =="
for f in .Renviron .env config.local.R; do
  if [ -e "$f" ]; then echo "  PRESENT (must be gitignored): $f"; fi
done

echo "== 2. key-shaped strings in tracked text =="
# e-INFRA keys observed as 'sk-...' or a long hex/base62 run.
hits=$(grep -rInE '(sk-[A-Za-z0-9_-]{16,}|Bearer[[:space:]]+[A-Za-z0-9._-]{20,}|api[_-]?key[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9._-]{20,})' \
        --exclude-dir=.git --exclude-dir=data --exclude=check_secrets.sh . 2>/dev/null || true)
if [ -n "$hits" ]; then echo "$hits"; fail=1; else echo "  none"; fi

echo "== 3. the live key, if it happens to be in this shell =="
if [ -n "${EINFRA_API_KEY:-}" ] && [ "${#EINFRA_API_KEY}" -ge 16 ]; then
  # Guard on length: a short placeholder ("x", "test") matches everywhere and
  # produces a false alarm, which is worse than no check - people learn to
  # ignore it.
  if grep -rIq --exclude-dir=.git -- "$EINFRA_API_KEY" . 2>/dev/null; then
    echo "  *** YOUR ACTUAL KEY APPEARS IN A FILE IN THIS REPO ***"; fail=1
  else echo "  not present in any file"; fi
elif [ -n "${EINFRA_API_KEY:-}" ]; then
  echo "  \$EINFRA_API_KEY is set but shorter than 16 chars - looks like a"
  echo "  placeholder, so skipping (a short string matches everything)."
else
  echo "  \$EINFRA_API_KEY not set in this shell - cannot check (run with it set)"
fi

echo
if [ "$fail" -eq 0 ]; then echo "PASS - nothing key-shaped found."; else echo "FAIL - fix the above before committing."; fi
exit $fail
