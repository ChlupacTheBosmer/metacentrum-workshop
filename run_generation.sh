#!/usr/bin/env bash
# Presenter-side launcher for the corpus run (artifact A1).
# The API key is read from the environment and never stored in this repo.
#   export EINFRA_API_KEY=...   then   ./run_generation.sh
set -euo pipefail
cd "$(dirname "$0")"
: "${EINFRA_API_KEY:?Set EINFRA_API_KEY first (see setup.md)}"
exec Rscript src/generate_corpus.R "$@"
