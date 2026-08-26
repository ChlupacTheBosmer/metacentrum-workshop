#!/usr/bin/env bash
# =============================================================================
# config.sh - shell mirror of config.R, for PBS scripts and terminal work.
# Keep the two files in sync. Same status legend as config.R.
# NEVER put an API key in here.
# =============================================================================

# ---- AI as a Service --------------------------------------------------------
# [VERIFIED 2026-08-23] docs.cerit.io/en/docs/ai-as-a-service/ai-api + live call
export EINFRA_API_BASE="https://llm.ai.e-infra.cz/v1"
export EINFRA_WEBUI="https://chat.ai.e-infra.cz"
# The key comes from the environment, never from this file:
#   export EINFRA_API_KEY=...   (put it in ~/.Renviron / ~/.bashrc, not in git)

# ---- OpenPBS ----------------------------------------------------------------
# [VERIFIED 2026-08-23] docs.metacentrum.cz/en/docs/computing/advanced
export WS_ARRAY_INDEX_VAR="PBS_ARRAY_INDEX"     # qsub -J X-Y[:Z]
export WS_N_REPLICATES=30

# ---- Software modules -------------------------------------------------------
# [VERIFY] T6 - run `module avail R/` on a frontend and paste the exact string.
export WS_R_MODULE="r/4.5.1-gcc-10.2.1-zmneq6c"   # [VERIFIED 2026-08-23]

# ---- Storage ----------------------------------------------------------------
# [VERIFY] T7 - literal paths, and that participants can READ the artifacts dir.
export WS_ARTIFACTS_DIR="/storage/plzen1/home/chlupp/workshop/artifacts"
export WS_RESULTS_DIR="/storage/plzen1/home/chlupp/workshop/results"
export WS_IMAGE="/storage/plzen1/home/chlupp/workshop/images/workshop-r.sif"

# ---- Guardrail --------------------------------------------------------------
ws_require() {
  local name="$1" val="${!1}"
  if [[ -z "$val" || "$val" == __VERIFY_* ]]; then
    echo "config.sh: \$$name is still [VERIFY] ('$val'). Resolve it in the owning T-test." >&2
    return 1
  fi
}
