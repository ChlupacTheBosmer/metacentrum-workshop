# =============================================================================
# config.R - SINGLE SOURCE OF TRUTH for every infrastructure-specific value.
# =============================================================================
# Repo-wide rule (handover Section 4.3): no script, exercise, slide or PBS file
# may hardcode a URL, model ID, module name, queue name or storage path.
# They all read from here. When the infrastructure changes, you edit ONE file.
#
# Status legend used throughout:
#   [VERIFIED yyyy-mm-dd] - confirmed against live docs or a live API call.
#                           Evidence recorded in CHANGELOG.md.
#   [VERIFY]              - NOT confirmed. Must be resolved by a T-test
#                           (handover Section 7) before the workshop.
#   [DECISION Dn]         - waiting on a presenter decision (handover Section 9).
#
# Usage:  source("config.R")   then use cfg$...
# =============================================================================

cfg <- list()

# -----------------------------------------------------------------------------
# 1. AI-as-a-Service (e-INFRA CZ / CERIT-SC)
# -----------------------------------------------------------------------------
cfg$ai <- list(

  # [VERIFIED 2026-08-23] docs.cerit.io/en/docs/ai-as-a-service/ai-api
  #   and a live 200 response from GET /v1/models.
  base_url    = "https://llm.ai.e-infra.cz/v1",

  # [VERIFIED 2026-08-23] Open WebUI. Login -> "Log in with e-INFRA CZ".
  #   API key: Settings -> Account -> API keys.
  webui_url   = "https://chat.ai.e-infra.cz",

  # [VERIFIED 2026-08-23] Bearer token in the Authorization header.
  auth_header = "Authorization",
  auth_scheme = "Bearer",

  # The key itself NEVER lives in this repo. Participants put it in ~/.Renviron
  # as:  EINFRA_API_KEY=...        (see setup.md)
  key_env_var = "EINFRA_API_KEY",

  # ---- Generation model -----------------------------------------------------
  # [VERIFIED 2026-08-23] Live-tested. CRITICAL FINDING: several models exposed
  # by this endpoint are *reasoning* models. They spend the max_tokens budget on
  # hidden reasoning tokens and return an EMPTY message.content. Verified empty
  # output from: mini, qwen3.8-27b, glm, kimi, gpt-oss-120b.
  # Only non-reasoning models are safe for the corpus generator.
  # Measured single-request latency (short review, max_tokens=200):
  #   qwen3.5-122b       1.6 s   <- fastest and largest of the safe set
  #   gemma4             2.4 s
  #   command-a          2.6 s
  #   mistral-medium-3.5 4.0 s
  # [CHANGED 2026-08-26] The previous default, qwen3.5-122b, VANISHED from the
  # service overnight: the model list went from 31 entries to 30 and requests
  # started returning HTTP 403 "Model is blocked". Its successors qwen3.5 and
  # qwen3.5-int4 answer with HTTP 200 but EMPTY text, which is worse.
  # Models on a shared service come and go. Never assume yesterday's works.
  # Measured working, 2026-08-26: gemma4 2.6s, command-a 3.6s, mistral 3.9s.
  chat_model          = "gemma4",
  chat_model_backup   = c("command-a", "mistral-medium-3.5"),
  # Models that must NOT be used for generation (they return empty content):
  # Models that answer with empty text. Two different causes, same symptom:
  # reasoning models spend the whole budget on hidden thinking, and some models
  # are simply broken on this endpoint.
  chat_models_unsafe  = c("mini", "qwen3.8-27b", "glm", "kimi",
                          "gpt-oss-120b", "deepseek-thinking", "thinker",
                          "qwen3.5", "qwen3.5-int4", "qwen3.5-122b"),

  # ---- Embedding model ------------------------------------------------------
  # [VERIFIED 2026-08-23] POST /v1/embeddings returns HTTP 200 with batched
  # input. Measured output dimensions:
  #   mxbai-embed-large:latest        1024
  #   multilingual-e5-large-instruct  1024
  #   qwen3-embedding-4b              2560
  #   nomic-embed-text-v1.5            768
  # This CLOSES open decision D2 (an embedding model IS exposed) but the CHOICE
  # among them is still [DECISION D2b] - see CHANGELOG.
  embed_model     = "mxbai-embed-large:latest",   # [DECISION D2b]
  embed_dim       = 1024L,                        # must match embed_model

  # ---- Throughput -----------------------------------------------------------
  # [VERIFIED 2026-08-23] from the presenter's laptop, single key:
  #   embeddings: batch of 128 texts in 0.86 s (~150 texts/s)
  #   chat: 8 concurrent requests -> 5.0 s wall, zero HTTP 429
  # [VERIFY] T3 must repeat this with ~15 DISTINCT keys at once (flash crowd)
  #   and from inside an OnDemand session, not a laptop.
  embed_batch_size    = 64L,

  # [VERIFIED 2026-08-23] The server publishes its own limit in a response header:
  #   x-ratelimit-api_key-limit-max_parallel_requests: 4
  # It is a limit on requests IN FLIGHT per key, not per time window. Sequential
  # requests are unthrottled (25 in 6.5 s, zero 429). We use 3 to leave headroom
  # for anything else the participant's session might be doing on the same key.
  # [MEASURED 2026-08-24 02:30] Set to 2, not 3, deliberately.
  # httr2's req_perform_parallel multiplexes over HTTP/2, so it puts MORE
  # requests in flight than `max_active` implies. At max_active=3 we generated
  # continuous 429s and every one cost an 8s backoff, dragging a 500-text shard
  # out to 480s. At 2 the 429s stop and throughput goes UP.
  # Isolated curl benchmark (separate processes, so a true concurrency count):
  #   conc 1 -> 0.49 texts/s | 2 -> 1.30 | 3 -> 1.23 | 4 -> 1.56 (with 429s)
  # Note the endpoint itself is ~5x slower under evening load than it was at
  # 19:30 (7.4 texts/s), so these numbers are a floor, not a constant.
  chat_concurrency    = 2L,

  # [VERIFIED 2026-08-23] A 429 from this endpoint carries `Retry-After: 1800`.
  # That is NOT a real 30-minute penalty - other requests on the same key
  # succeeded in the same second. Clients that trust Retry-After hang for half
  # an hour. api_client.R therefore ignores the header and uses this bound.
  backoff_max_sec     = 8,
  max_retries         = 5L,
  backoff_base_sec    = 1.0
)

# -----------------------------------------------------------------------------
# 2. MetaCentrum Grid / OpenPBS
# -----------------------------------------------------------------------------
cfg$pbs <- list(
  # [VERIFIED 2026-08-23] docs.metacentrum.cz/en/docs/computing/advanced
  array_flag      = "-J",                 # qsub -J X-Y[:Z] script.sh
  array_index_var = "PBS_ARRAY_INDEX",    # NOT PBS_ARRAYID on this system
  array_id_var    = "PBS_ARRAY_ID",

  # [VERIFIED 2026-08-23] docs.metacentrum.cz/en/docs/computing/run-basic-job
  submit_cmd  = "qsub",
  status_cmd  = "qstat -u $USER",
  status_all  = "qstat -x -u $USER",      # includes Finished jobs
  status_subjobs = "qstat -t",            # expands array subjobs
  delete_cmd  = "qdel",
  select_line = "#PBS -l select=1:ncpus=%d:mem=%dgb:scratch_local=%dgb",
  walltime_line = "#PBS -l walltime=%s",
  scratch_var = "SCRATCHDIR",             # $SCRATCHDIR, cleaned by clean_scratch

  # Resource request for one replicate fit. [VERIFY] tune in T6/T8.
  rep_ncpus    = 4L,   # one core per chain
  rep_mem_gb   = 4L,
  rep_scratch_gb = 2L,
  rep_walltime = "00:30:00",
  n_replicates = 30L,

  # [VERIFY] T6: is there a per-user concurrent-job cap that 15 users x 30 jobs
  #   would hit? Which queue do these land in by default?
  # [VERIFIED 2026-08-23, T6b] A 3-job array submitted from zenith landed in
  # queue q_2h (auto-selected from walltime; do NOT name a queue explicitly).
  # Queue wait at ~20:00 on a Sunday was ~100 seconds. Jobs ran on zenon1.
  queue        = "q_2h",
  frontend     = "zenith.metacentrum.cz",   # = zenith.cerit-sc.cz
  # [VERIFIED 2026-08-23, T6b] observed values inside a running subjob:
  #   $PBS_ARRAY_INDEX  -> 1, 2, 3
  #   $PBS_ARRAY_ID     -> 23130368[].pbs-m1.metacentrum.cz
  #   $SCRATCHDIR       -> /scratch.ssd/<user>/job_<id>[<i>].pbs-m1
  #   $PBS_O_WORKDIR    -> the submit directory on shared storage
  #   stdout            -> <jobname>.o<jobid>.<index> in the submit directory
  #                        (e.g. ws_arraytest.o23130368.1 - DOT index, not [i])
  scratch_root = "/scratch.ssd"
)

# -----------------------------------------------------------------------------
# 3. Open OnDemand
# -----------------------------------------------------------------------------
cfg$ondemand <- list(
  # [VERIFIED 2026-08-23] docs.metacentrum.cz/en/docs/graphical/ondemand
  url = "https://ondemand.metacentrum.cz",
  # [VERIFIED 2026-08-24 from the presenter's dashboard screenshot]
  #   OnDemand version 4.0.7. Top nav: Files / Jobs / Clusters / Interactive
  #   Apps / My Interactive Sessions. Selected applications tiles:
  #   Jupyter Lab/Notebook, RStudio, Matlab, Ansys Fluent/Ensight/Workbench,
  #   Perian Shell Access, MetaCentrum Desktop, Job Composer, BIOP Desktop,
  #   MZMINE, VMD Desktop.
  #   The dashboard also shows a per-volume QUOTA BANNER - the presenter's
  #   brno2 was at 93% (3.93 TB of 4.19 TB), which is why artifacts live on
  #   plzen1. Good Block 0 material: the cluster tells you about storage
  #   pressure before you hit it.
  version_seen = "4.0.7",
  # [VERIFIED 2026-08-23] RStudio Server and Jupyter are both listed as
  #   Interactive Apps. The docs page does NOT document the session form fields.
  # [VERIFY] T5: exact field names/limits on the RStudio session request form,
  #   available R versions, startup latency, and OUTBOUND NETWORK EGRESS to
  #   llm.ai.e-infra.cz from inside a compute session (risk R10 - this decides
  #   whether Blocks 2-3 can run where we plan to run them).
  # [VERIFIED 2026-08-23, T6b] *** Risk R10 is CLOSED. ***
  # A compute node (zenon1.cerit-sc.cz) reached https://llm.ai.e-infra.cz/v1/models
  # with HTTP 401 (i.e. the host answered; only the missing key was refused) in
  # 43 ms, and https://cloud.r-project.org/ with HTTP 200. No proxy variables are
  # set and none are needed. Blocks 2-3 can run inside a compute session.
  compute_egress_ok = TRUE,

  starter_cores  = 4L,     # [VERIFY] against the real form options
  starter_mem_gb = 16L,
  starter_walltime = "8:00:00",
  heavy_cores    = 12L,    # for the Block 4 cores=1 vs cores=N comparison
  heavy_mem_gb   = 32L
)

# -----------------------------------------------------------------------------
# 4. Software modules
# -----------------------------------------------------------------------------
cfg$modules <- list(
  # [VERIFIED 2026-08-23] docs.metacentrum.cz/en/docs/software/modules
  #   Commands: module avail / add / load / list / unload / purge.
  #   Wildcard search works: `module avail *R*`, trailing "/" lists versions.
  # [VERIFY] T6: the EXACT R module name and version string. The docs page has
  #   no R example. Do not guess - run `module avail R/` on a frontend.
  # [VERIFIED 2026-08-23, T6a] `module avail r/` on zenith. Newest is 4.5.1;
  # the cluster default is the much older r/4.1.3-gcc-10.2.1-6xt26dl.
  # NOTE: never pipe `module add` - it runs in a subshell and the PATH change
  # is lost. This cost us a confusing "R: command not found".
  r_module      = "r/4.5.1-gcc-10.2.1-zmneq6c",
  module_root   = "/packages/run/modules-5/debian12avx512",
  extra_modules = character(0),

  # [VERIFIED 2026-08-23] *** The bare r/ module has NO packages. ***
  # Checked inside the module: httr2, jsonlite, dplyr, readr, tidyr, ggplot2,
  # rstan, cmdstanr, posterior, uwot, arrow, future, furrr, Rcpp, RcppEigen, BH
  # -> ALL MISSING. The module ships base R and nothing else.
  #
  # MetaCentrum's prepared RStudio image is much better but still incomplete:
  #   /storage/singularity.metacentrum.cz/RStudio/.RStudio-geospatial-4.5.1.upd3.SIF
  #   present : httr2 jsonlite dplyr readr tidyr ggplot2 arrow Rcpp BH
  #   missing : rstan cmdstanr posterior loo bayesplot uwot future furrr RcppEigen
  # So Blocks 2-3 work out of the box; Block 4 (Stan) does NOT.
  # This is what decision D7's Singularity image has to solve.
  # [VERIFIED 2026-08-24, presenter checked the live OnDemand form]
  # *** The OnDemand RStudio app does NOT accept a custom image. ***
  # So our container is for PBS jobs only; the interactive session is stuck with
  # MetaCentrum's fixed image and needs packages installed into a library.
  rstudio_image_selectable = FALSE,
  rstudio_image = "/storage/singularity.metacentrum.cz/RStudio/.RStudio-geospatial-4.5.1.upd3.SIF",

  # Our container - used by PBS jobs (Block 5) and as the Stan fallback.
  workshop_image = "/storage/plzen1/home/chlupp/workshop/images/workshop-r.sif",

  # The shared R library + pre-built CmdStan, built INSIDE the RStudio image so
  # the compiled objects are binary-compatible with the interactive session.
  # Participants add ONE line instead of compiling anything:
  #     .libPaths(c(cfg$modules$shared_rlibs, .libPaths()))
  shared_rlibs   = "/storage/plzen1/home/chlupp/workshop/Rlibs",
  shared_cmdstan = "/storage/plzen1/home/chlupp/workshop/cmdstan/cmdstan-2.39.0",

  # [VERIFIED 2026-08-24] Pre-compiled Stan binary. Compiling model.stan takes
  # ~7 MINUTES (CPU-bound in Stan Math's headers); loading this takes 0.32 s.
  precompiled_model = "/storage/plzen1/home/chlupp/workshop/artifacts/model_binary"
)

# -----------------------------------------------------------------------------
# 5. Storage
# -----------------------------------------------------------------------------
# There are two kinds of path here, and mixing them up causes real problems.
#
#   SHARED, read only.   One copy, made by the presenter, that everybody reads.
#                        The R packages, Stan, the data, the container.
#
#   YOURS, writable.     Built from your own username. Where you cloned the
#                        repository, and where your results go.
#
# The second kind MUST be per user. If everyone wrote results to the same
# folder, five people running the same job array would each write rep_001.rds
# on top of each other.
# -----------------------------------------------------------------------------

# Your username, as the system reports it.
ws_username <- Sys.getenv("USER", unset = Sys.getenv("USERNAME", unset = ""))
if (!nzchar(ws_username)) {
  warning("Could not work out your username from the environment. ",
          "Paths built from it will be wrong.")
}

# The storage volume the workshop uses. One place, so the instructions are the
# same for everybody.
ws_volume <- "plzen1"

cfg$storage <- list(

  # ---- shared, read only ----------------------------------------------------
  # [VERIFIED 2026-08-23, T7] Homes exist on EVERY site, path template:
  #   /storage/<site>/home/<username>
  # Sites seen: brno2, brno11-elixir, brno12-cerit, brno14-ceitec, brno3-cerit,
  #   budejovice1/2a-2d, liberec3-tul, plzen1, plzen2-zcu, plzen4-ntis, praha1,
  #   praha2-natur, praha5-elixir, praha6-fzu, pruhonice1-ibot, vestec1-elixir
  home_template   = "/storage/%s/home/%s",

  # E1 revised 2026-08-23: moved from brno2 to plzen1. brno2 was at 4.02 TB of
  # a 4.29 TB quota (~94%, flagged red in the login banner); plzen1 has the same
  # quota class with only 73 GB used, and 974 TB free on the volume.
  artifacts_dir   = "/storage/plzen1/home/chlupp/workshop/artifacts",
  image_path      = "/storage/plzen1/home/chlupp/workshop/images/workshop-r.sif",
  quota_note      = "plzen1 3.22T quota / 73G used (brno2 was 94% full - avoided)",

  # [VERIFIED 2026-08-23, T6b] node-local scratch, per job
  scratch_var     = "SCRATCHDIR"
)

# ---- the per user paths, built from the username ----------------------------
cfg$storage$username <- ws_username
cfg$storage$volume   <- ws_volume

# Where you cloned the repository. bootstrap.sh puts it here, for everybody,
# so that every path printed on a slide works on every laptop in the room.
cfg$storage$repo_dir <- sprintf("/storage/%s/home/%s/metacentrum-workshop",
                                ws_volume, ws_username)

# Your own results. Inside your own clone, so nobody collides.
cfg$storage$results_dir <- file.path(cfg$storage$repo_dir, "results")

# -----------------------------------------------------------------------------
# 6. Experimental design (project spine, handover 2.3)
# -----------------------------------------------------------------------------
cfg$design <- list(
  # Live slice each participant generates: 3 topics x 2 sentiments x 10 reps
  live_topics     = 3L,
  live_sentiments = 2L,
  live_reps       = 10L,            # -> 60 texts

  # Full pre-generated corpus. [DECISION D4] default 50000.
  full_n_topics   = 25L,
  full_n_texts    = 50000L,         # [DECISION D4]

  n_pcs           = 30L,            # PCs kept as model predictors
  n_varying_slopes = 3L,            # PC1-PC3 slopes vary by topic (handover F6)
  seed            = 20260823L
)

# -----------------------------------------------------------------------------
# 7. Modelling backend
# -----------------------------------------------------------------------------
cfg$model <- list(
  backend = NA_character_,  # [DECISION D1] "brms" or "rstan"/"cmdstanr"
  chains  = 4L,
  iter_warmup  = 1000L,
  iter_sampling = 1000L,
  # Replicate fits. Originally 2 chains x 500 to be kind to walltime, but the
  # measured replicate takes ~1 min against a 1 h walltime, so that thrift was
  # buying nothing and costing accuracy: tau[2] came out at 0.142 across
  # replicates against 0.260 fitting the same data directly, and 36 divergences
  # appeared across 60 fits. tau is a variance parameter and the hardest thing
  # in the model to estimate - it is the first casualty of a short chain.
  rep_chains = 4L,
  rep_iter_warmup = 750L,
  rep_iter_sampling = 750L
)

# -----------------------------------------------------------------------------
# Guardrail: fail loudly rather than silently using a placeholder.
# -----------------------------------------------------------------------------
cfg_require <- function(path) {
  v <- Reduce(function(a, b) a[[b]], strsplit(path, "$", fixed = TRUE)[[1]], cfg)
  if (length(v) == 0 || all(is.na(v))) {
    stop("config.R: '", path, "' is still [VERIFY]/unset. ",
         "Resolve it via the T-test that owns it before running this script.",
         call. = FALSE)
  }
  v
}
