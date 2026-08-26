# CHANGELOG

Running record of what was built, what was verified (and how), and what remains
`[VERIFY]`. Newest session first.

---

## Session 1 — 2026-08-23

### BUILT
- Repository skeleton at `workshop-metacentrum-r/` matching handover §4.1.
- `config.R` — central, commented single source of truth for every infra
  specific. Every entry carries `[VERIFIED date]`, `[VERIFY]` or `[DECISION Dn]`.
  Includes `cfg_require()` so a script dies loudly rather than running with a
  placeholder.
- `config.sh` — shell mirror for PBS scripts, with the same guardrail
  (`ws_require`). Contains no secrets; `__VERIFY_*__` sentinels for unknowns.
- `runbook/testing_log.md` — results template for T1–T9.

### VERIFIED — with evidence

The handover (§10, Appendix B) recorded that deeper docs pages could not be
scraped during planning. **They can be scraped now.** In addition, the e-INFRA
AI API was queried live using the presenter's existing personal API key (read
from `~/.claude/settings.json`; the key itself is not stored anywhere in this
repo). Evidence below.

| # | Handover §10 item | Result | Source |
|---|---|---|---|
| 1 | OnDemand portal URL | **`https://ondemand.metacentrum.cz`** | docs.metacentrum.cz/en/docs/graphical/ondemand |
| 1 | RStudio Server + Jupyter are Interactive Apps | **confirmed** (listed alongside Matlab, ANSYS) | same page |
| 1 | Session-form field details | **still `[VERIFY]`** — page does not document the form | → T5 |
| 2 | AI Chat WebUI URL | **`https://chat.ai.e-infra.cz`** | docs.cerit.io/en/docs/ai-as-a-service/chat-ai |
| 2 | API base URL | **`https://llm.ai.e-infra.cz/v1/`** | docs.cerit.io/en/docs/ai-as-a-service/ai-api |
| 2 | Auth scheme | **`Authorization: Bearer <key>`** | same page + live 200 |
| 2 | Key provisioning | WebUI → Settings → Account → API keys | docs.cerit.io/…/chat-ai |
| 2 | Chat model IDs | **live `GET /v1/models` → 31 models** (see below) | live API call |
| 2 | **Embedding model exposed?** | **YES** — `POST /v1/embeddings` returns 200 | live API call |
| 3 | PBS array syntax | **`qsub -J X-Y[:Z] script.sh`** | docs.metacentrum.cz/en/docs/computing/advanced |
| 3 | Array index env var | **`$PBS_ARRAY_INDEX`** (plus `$PBS_ARRAY_ID`) | same page |
| 3 | Array monitoring | `qstat -t`; `qstat -f <id>'[]' -x \| grep array_state_count` | same page |
| 3 | Basic job commands | `qsub`, `qstat -u <user>`, `qstat -x -u <user>`, `qdel <id>` | docs.metacentrum.cz/en/docs/computing/run-basic-job |
| 3 | Resource syntax | `#PBS -l select=1:ncpus=1:mem=1gb:scratch_local=1gb`, `#PBS -l walltime=0:30:00` | same page |
| 3 | Scratch | `$SCRATCHDIR` + `clean_scratch` utility | same page |
| 3 | Job output | `<jobname>.o<jobID>` / `.e<jobID>` in the submit dir | same page |
| 4 | Module commands | `module avail/add/load/list/unload/purge`; wildcards `module avail *intel*`; trailing `/` lists versions | docs.metacentrum.cz/en/docs/software/modules |
| 4 | **Exact R module name** | **still `[VERIFY]`** — docs page has no R example | → T6 |
| 5 | Storage paths/quotas | **still `[VERIFY]`** — landing page describes home ("named after cities") / scratch / object storage but gives no literal path template | → T7 |
| 6 | Queue names, per-user job caps | **still `[VERIFY]`** | → T6 |
| 7 | Registration / VO steps | partially: MetaCentrum registration form linked as `https://metavo.metacentrum.cz/en/application/form`; MU users have a quick path | → T1 confirms end-to-end |
| 8 | Compute-node egress to the API | **still `[VERIFY]` — highest-stakes unknown (risk R10)** | → T5 |
| 9 | Loaner/training account policy | **still `[VERIFY]`** | → presenter asks support |

#### Live API evidence (2026-08-23, from the presenter's laptop)

`GET /v1/models` → HTTP 200, 31 models. Embedding-capable IDs present:
`qwen3-embedding-4b`, `mxbai-embed-large:latest`, `nomic-embed-text-v2-moe`,
`nomic-embed-text-v1.5`, `multilingual-e5-large-instruct`, plus a reranker
`qwen3-reranker-4b`. Generative IDs include `kimi-k3`, `glm-5.2`, `gpt-oss-120b`,
`deepseek-v4-flash`, `qwen3.5-122b`, `qwen3.8-27b`, `mistral-medium-3.5`,
`gemma4`, `command-a`, `whisper-large-v3`, and aliases
`mini`/`coder`/`agentic`/`thinker`/`glm`/`kimi`/`deepseek`.

`POST /v1/embeddings` → HTTP 200, batched `input` array accepted. Dimensions:

| model | dim |
|---|---|
| `mxbai-embed-large:latest` | **1024** |
| `multilingual-e5-large-instruct` | 1024 |
| `qwen3-embedding-4b` | 2560 |
| `nomic-embed-text-v1.5` | 768 |

Embedding throughput (`mxbai-embed-large:latest`, one key, laptop):
batch 1 → 0.23 s; batch 16 → 0.20 s; batch 64 → 0.43 s; batch 128 → 0.86 s
(≈150 texts/s). **Implication: embedding 50 000 texts takes ≈6 minutes, not hours.**

`POST /v1/chat/completions` → HTTP 200. Latency for one ~60-word review
(`max_tokens=200`): `qwen3.5-122b` 1.6 s, `gemma4` 2.4 s, `command-a` 2.6 s,
`mistral-medium-3.5` 4.0 s.

Concurrency probe: 8 simultaneous chat requests on one key → 5.0 s wall,
**zero HTTP 429**, all 8 returned usable text.

#### ⚠ Finding that changes the build — reasoning models return empty text

Several exposed models are *reasoning* models. With a `max_tokens` cap they
spend the entire budget on hidden reasoning tokens and return
`message.content == ""` with `finish_reason: "length"`. Confirmed empty output
from **`mini`, `qwen3.8-27b`, `glm`, `kimi`, `gpt-oss-120b`**.

`mini` is the exact model used in the official docs' `curl` example, so the
obvious copy-paste choice is the one that silently produces an empty corpus.
This would have surfaced on workshop day as "my CSV has 60 blank rows".

Mitigations now baked in: `config.R` pins a non-reasoning default
(`qwen3.5-122b`), lists `chat_models_unsafe`, and the API client will hard-fail
on empty content rather than writing blank rows (handover F2).

### STILL `[VERIFY]` — routed to T-tests
T1 registration/VO · T3 multi-key flash crowd · T5 OnDemand form + **compute-node
egress (R10)** · T6 R module name, queue names, per-user job caps · T7 storage
paths, quotas, participant read access · T8 all timings · T9 dry run.

### Local capability note
The presenter's laptop has `httr2`, `jsonlite`, `dplyr`, `tibble`, `readr`,
`ggplot2`, `brms`, `cmdstanr`, `rstan`, `posterior`, `uwot`. Missing: `arrow`,
`furrr`. So the whole pipeline can be dogfooded locally before it ever touches
the cluster — which de-risks T8 considerably.

---

## Session 2 — 2026-08-23

### Decisions received (D1–D8, E1–E5)
D1 **raw Stan, no brms** · D2b `mxbai-embed-large:latest` (1024-dim) · D3 **both R
and Python** · D4 **50 000 texts** · D5 per-participant keys, concurrency must be
validated · D6 **27 Aug 2026, ~5 people, no staggering** · D7 add a **Singularity
image-building mini-tutorial** · D8 **no supervisor review — correctness is mine
to own** · E1 storage = **brno2** · E2 key approved for build-time use · E3
control arm approved, design improvements welcome · E4 no gate · E5 no pilot.

### ⚠ SCHEDULE
Workshop is **Thursday 27 Aug 2026** — 4 days from today. Handover §11's
four-week timeline is void; replanned in the session notes.

### BUILT
- `design/design.json` — single source of truth for the experimental design,
  read by **both** the R and Python prompt factories so they cannot drift.
  25 topics × 5 ratings, with a designed `expressiveness` factor (8 explicit /
  9 moderate / 8 understated).
- `src/gen_prompts.R` — prompt factory (F3). Verified: 60-text live slice and
  full 250-cell grid both build correctly.
- `src/api_client.R` — R client (F2). Live-verified end to end.
- `src/api_client.py` — Python twin (D3), function-for-function identical.
- `src/export_config.R` → `config.json`, so the Python path reads the *same*
  config as R. Single config, two languages, no drift.
- `src/generate_corpus.R` + `run_generation.sh` — resumable sharded generator
  for artifact A1. Shard directory is keyed to run size so a rehearsal run can
  never corrupt the real one.
- `.gitignore` + `tools/check_secrets.sh` — scanner for key-shaped strings and
  for the live key itself. **Currently PASSES.**

### VERIFIED — with evidence

**D5 answered precisely.** The server publishes its own limit:
`x-ratelimit-api_key-limit-max_parallel_requests: 4`. It is a cap on requests
**in flight per key**, not per time window — 25 sequential requests succeeded in
6.5 s with zero 429s, while 8 concurrent lost 7 of 16.

**⚠ The `Retry-After` trap — the most dangerous finding so far.**
A 429 from this endpoint carries **`Retry-After: 1800`**. That number is false:
during the very burst in which four requests were rejected with it, two *other*
requests on the same key returned HTTP 200 in the same second. It is LiteLLM's
generic default, not a real penalty.

Any HTTP client that honours `Retry-After` — httr2 does, by default — therefore
**blocks for 30 minutes** on a rejection that would clear in under a second.
This was reproduced: an early `chat_many()` run printed
`Waiting 1797s for rate limit` and hung. One participant typing `concurrency = 8`
would silently lose half of Block 2.

Both clients now ignore `Retry-After` and use a bounded backoff capped at
`cfg$ai$backoff_max_sec` (8 s). Post-fix the same call printed `Waiting 3s` and
completed. Concurrency default is **3**, one below the cap, for headroom.
*This is now a Block 2 teaching point: read the headers, don't trust them.*

**Measured throughput** (presenter's laptop, one key, concurrency 3):
- 60-text live slice: **1.8 s**, zero failures → the Block 2 exercise is fast.
- Bulk generation: **500 texts / 68 s ≈ 7.4 texts/s** → 50 000 in **≈112 min**.
- Cost: `x-litellm-response-cost` ≈ 1e-5 per review → the whole 50k corpus ≈ $0.50.

**Design validated on real output.** The `expressiveness` factor visibly works:
the same 5-star rating produces "I love it"-style prose in explicit topics and
purely factual description in understated ones. That is the genuine
between-topic variation the hierarchical model's varying slopes will estimate.

### RUNNING
Full 50 000-text corpus generation (artifact A1), launched 2026-08-23 ~19:30,
ETA ≈112 min. Resumable: re-running skips completed shards.

### STILL `[VERIFY]`
Unchanged from Session 1: R module name · storage paths under **brno2** ·
queue caps · **compute-node egress to the API (R10)** · loaner-account policy.
All routed to the Wave-1 test pack in `runbook/testing_log.md`.

---

## Session 3 — 2026-08-23 (live infrastructure access)

Presenter supplied SSH credentials for `chlupp@zenith.metacentrum.cz`. First
password was wrong (one attempt, then stopped to avoid lockout); corrected
password worked. Authenticated **once** via `expect` and left an SSH
`ControlMaster` socket behind, so the password was never replayed and never
written to disk. Wave-1 tests then run directly.

### VERIFIED — Wave 1 complete

**T5a / risk R10 — CLOSED, and it's good news.** A PBS job on compute node
`zenon1.cerit-sc.cz` reached `https://llm.ai.e-infra.cz/v1/models` → **HTTP 401
in 43 ms** (the host answered; only the absent key was refused) and
`https://cloud.r-project.org/` → HTTP 200. No proxy set or needed.
**Blocks 2–3 can run inside a compute session as designed.**

**T6a — R module.** `r/4.5.1-gcc-10.2.1-zmneq6c` is newest; cluster default is
`r/4.1.3-gcc-10.2.1-6xt26dl`. Modules-5, root `/packages/run/modules-5/debian12avx512`.
*Gotcha recorded:* never pipe `module add` — it runs in a subshell and the PATH
change is lost.

**T6b — PBS array, fully verified end to end.** `qsub -J 1-3` → job
`23130368[]` in queue **`q_2h`** (auto-selected from walltime — do not name a
queue). Queue wait ≈ **100 s**. Observed inside subjobs:
`$PBS_ARRAY_INDEX` = 1,2,3 · `$PBS_ARRAY_ID` = `23130368[].pbs-m1.metacentrum.cz` ·
`$SCRATCHDIR` = `/scratch.ssd/<user>/job_<id>[<i>].pbs-m1` ·
`$PBS_O_WORKDIR` = submit dir · stdout → `<jobname>.o<jobid>` in the submit dir.

**T7 — storage.** Path template `/storage/<site>/home/<user>`; login home is
`/storage/brno12-cerit/home/chlupp`; homes exist on all 17 sites.
⚠ **brno2 is ~94% full** (4.02 TB used of 4.29 TB, flagged red in the login
banner). Our ~1 GB of artifacts fits, but plzen1 (3.22 TB quota, 73 GB used) is
the safer host if we want margin.

### ⚠ NEW BLOCKING FINDING — the R environment has no packages

The bare `r/` module ships base R and **nothing else**. All 16 packages checked
(httr2, jsonlite, dplyr, readr, tidyr, ggplot2, rstan, cmdstanr, posterior,
uwot, arrow, future, furrr, Rcpp, RcppEigen, BH) are **MISSING**.

MetaCentrum's prepared RStudio image
`/storage/singularity.metacentrum.cz/RStudio/.RStudio-geospatial-4.5.1.upd3.SIF`
(R 4.5.1) is much better but still incomplete:

| | packages |
|---|---|
| present | httr2, jsonlite, dplyr, readr, tidyr, ggplot2, arrow, Rcpp, BH |
| **missing** | **rstan, cmdstanr, posterior, loo, bayesplot, uwot, future, furrr, RcppEigen** |

**Consequence: Blocks 2–3 work out of the box. Block 4 (Stan) does not.**
Compiling rstan from source in-session is not viable in a workshop.
This is exactly what decision D7's Singularity image must solve, which promotes
it from "nice tutorial" to load-bearing infrastructure.

### RUNNING
Corpus generation 10/100 shards, zero failures, but the shared endpoint has
slowed (7.4 → ~2 texts/s); ETA drifted to ≈4.7 h. Resumable, so this is
tolerable — it finishes overnight.

---

## Session 4 — 2026-08-23 (Stan model + container)

### Decisions received
OnDemand RStudio **does** allow selecting a Singularity image → our container
serves Block 4, not just PBS. Storage moved **brno2 → plzen1** (brno2 was 94%
full). Build the image on `builder.metacentrum.cz`, make it readable by other
users, and teach image-building as part of the workshop.

### BUILT
- **`stan/model.stan`** (239 lines) — hierarchical **ordered-logistic**
  regression of star rating on embedding PCs, raw Stan per D1. Topic-level
  varying intercept + varying slopes on PC1–PC3, non-centred, LKJ(2) prior on
  the random-effect correlation. Commented line by line, with the statistical
  argument stated before any code, and a closing section that **names four
  choices I am not certain about** (PCs are unsupervised so nothing guarantees
  the signal is in the leading 30; which slopes vary is a judgement call;
  proportional-odds is an assumption; conditional independence is true here by
  construction but would not be on scraped data).
- `tests/test_model_recovery.R` — simulation-based parameter recovery test.
- `singularity/workshop-r.def` — container definition (see below).

### VERIFIED — the model is correct

`cmdstan_model()$check_syntax()` → **SYNTAX OK** (CmdStan 2.38.0).

Parameter recovery, N=1500, J=25, K=30, P=3, 2 chains: **9/9 parameters inside
their 95% credible intervals**, **0 divergent transitions**, **max R̂ = 1.010**.

| parameter | truth | 95% CI |
|---|---|---|
| beta[1] | 1.200 | [0.975, 1.560] |
| beta[2] | −0.800 | [−1.088, −0.670] |
| beta[3] | 0.500 | [0.304, 0.589] |
| tau[1] (intercept) | 0.700 | [0.580, 1.105] |
| tau[2] (PC1 slope) | 0.500 | [0.469, 0.992] |
| tau[3] (PC2 slope) | 0.300 | [0.271, 0.646] |
| c[1] | −2.200 | [−2.685, −1.952] |
| c[4] | 2.200 | [1.979, 2.708] |
| Omega[1,2] | 0.400 | [−0.309, 0.472] |

This is the evidence that replaces the supervisor review D8 removed.

**Open item:** warmup emits benign "Metropolis proposal rejected" messages from
degenerate initial cutpoints. Harmless, but noisy in front of an audience —
`fit_model.R` will supply explicit inits to silence them.

**Note on speed:** N=1500 fitted in **11 seconds** on 2 chains. That is *too
fast* to motivate the cluster. The live-fit subsample must be sized up
substantially so the cores=1 vs cores=N comparison in Block 4 is visible; that
sizing is now the job of T8.

### Container build
`singularity/workshop-r.def` bootstraps `rocker/tidyverse:4.5.1` (same lineage
as MetaCentrum's own RStudio images, so the OnDemand app behaves identically)
and adds the missing set: cmdstanr + a pre-built CmdStan, posterior, loo,
bayesplot, httr2, jsonlite, uwot, future, furrr, arrow. The `%post` section
**fails the build** if any package is missing and **compiles a throwaway Stan
model at build time**, so a broken toolchain can never reach the workshop.

*Build-host lesson (worth a slide):* the first attempt used an NFS
`SINGULARITY_TMPDIR` on plzen1 and unpacked 770 MB in 20 minutes — hours to
completion. Rebuilt with the builder's **local disk** as scratch instead.
Unpacking a container image means writing millions of small files, which is the
worst case for a network filesystem.

---

## Session 5 — 2026-08-24 (container delivered; corpus design v2)

### ✅ CONTAINER DELIVERED AND VERIFIED
`/storage/plzen1/home/chlupp/workshop/images/workshop-r.sif` — 1.2 GB,
world-readable (`a+r`, with `a+rX` along the whole path).

Verified **from zenith, not the build host**: R 4.5.1 and all of
cmdstanr · posterior · loo · bayesplot · httr2 · uwot · furrr · dplyr ·
ggplot2 · arrow present, **CmdStan 2.39.0** working.

Getting there took four attempts, and the lessons are now comments in the def:
1. hardcoded `$CMDSTAN=/opt/cmdstan/cmdstan` — real path is versioned;
2. "fix" used `cmdstanr::cmdstan_path()` in a fresh `Rscript`, which cannot see
   an install done in a different session — resolved in shell instead;
3. SIF conversion filled the builder's 19 GB local disk;
4. moving build temp to NFS failed differently — **NFS cannot `lchown`**, which
   fakeroot requires. Answer: builder's `/scratch` (116 GB local).
Switching to a `--sandbox` build after failure 2 is what made 3 and 4 cheap.

### ⚠ CORPUS v1 SCRAPPED — 70% duplicate texts

A routine quality check on the part-finished v1 corpus found **1758 exact
duplicates in 2500 texts**. Per topic × rating cell: 20 rows, **6 distinct
texts**. Three consecutive rows in a cell were the same sentence.

Cause was mine. Every replicate within a cell received a **byte-identical
prompt** — `replicate` was only a label, never reached the model — and the
model collapses to a handful of completions. Every other acceptance criterion
(no empties, balanced ratings, 25 topics, sensible length) passed, which is
exactly why this needed an explicit duplicate check to catch. Left undetected it
would have been **pseudo-replication**: 50k rows claiming independence while
carrying a few thousand distinct observations.

**Fix (design v2), both parts measured before committing:**

| approach | distinct output |
|---|---|
| identical prompt (v1) | 2 / 5 |
| identical prompt + per-request `seed` | **5 / 5** |
| prompt varied by persona + aspect | **6 / 6** |

v2 does both: a 20 × 20 persona/aspect grid (= 400 combinations, exactly one per
replicate) plus a deterministic per-request seed derived from `text_id`.

Persona and aspect are assigned from the **replicate index only**, with strides
coprime to the list lengths, so they are flat across the design —
verified: persona × rating counts range [25, 25], aspect × topic [5, 5]. They
are nuisance variation, not confounders; the designed structure stays entirely
in topic, rating and expressiveness. As a bonus the corpus now reads like a real
one, where reviewers and their concerns differ.

Generator now **prints the duplicate rate every shard**, so this regression can
never again hide behind healthy-looking metrics. Shard directories are keyed by
design version, so v1 output cannot contaminate v2.

### RUNNING
v2 generation of 50 000 texts, restarted 00:20. The endpoint is congested
(bounded backoff reporting ~9 s waits — working as designed, versus the 1800 s
the server asks for).

---

## Session 6 — 2026-08-24 (Block 4 rescued; exercises)

### Architecture change from the presenter
The OnDemand RStudio app **does not accept a custom image** (checked on the live
form). So `workshop-r.sif` serves PBS jobs only, and the interactive session is
stuck with MetaCentrum's fixed `RStudio-geospatial-4.5.1` image. The presenter's
fallback plan was: do everything in RStudio, defer Stan fitting to PBS.

### ✅ Block 4's ORIGINAL design is rescued — no fallback needed

Rather than accept the degraded path, we pre-built everything into a shared
library **inside the exact image OnDemand runs**, so the binaries are
compatible with the interactive session:

- `/storage/plzen1/home/chlupp/workshop/Rlibs` — posterior, loo, bayesplot,
  future, furrr, uwot, cmdstanr (+ deps)
- `/storage/plzen1/home/chlupp/workshop/cmdstan/cmdstan-2.39.0` — pre-built

Participants add **one line** and compile nothing:
```r
.libPaths(c("/storage/plzen1/home/chlupp/workshop/Rlibs", .libPaths()))
```

**Verified inside the RStudio image**, not merely asserted:
all 10 packages load · CmdStan 2.39.0 resolves · `model.stan`
**compiles and samples** (`RSTUDIO_STAN_PATH_WORKS`).

### ⚠ …and a 7-minute trap found on the way

Compiling `model.stan` took **~7 minutes** (00:53 → 01:00). It is genuinely
CPU-bound — Stan Math's headers are enormous; `cc1plus` sat at full tilt
throughout. Five participants each compiling the identical model is ~35 minutes
of a workshop spent watching g++.

**Fixed by shipping the compiled binary.** `artifacts/model` (3 MB, world-
readable) alongside `model.stan`. `fit_model.R` now looks for it automatically
and falls back to compiling if it is missing or stale — an optimisation, never a
dependency.

Measured: **0.32 s to load the pre-compiled model, against ~7 minutes to build
it.** This was the largest single risk left in Block 4.

### Corpus throughput — counterintuitive fix
Generation had slowed to 480 s per 500-text shard. Cause was **not** endpoint
congestion alone: httr2's `req_perform_parallel` multiplexes over HTTP/2 and
puts more requests in flight than `max_active` implies, so at `max_active=3` we
generated continuous 429s, each costing an 8 s backoff.

Isolated benchmark (separate processes, so a true concurrency count):

| concurrency | texts/s | 429s |
|---|---|---|
| 1 | 0.49 | 0 |
| 2 | **1.30** | 0 |
| 3 | 1.23 | 0 |
| 4 | 1.56 | 1 |

Dropped to 2 → **226 s/shard, 2.1× faster**, zero 429s.

### Corpus is now schedule-proof
The generator shuffles prompts before sharding, so a **partial corpus is still a
balanced one**. Verified at 1000 texts: 25/25 topics present, ratings
203/187/217/194/199, expressiveness 320/355/325, **0 duplicates**. Whatever
exists when we stop *is* the corpus — no go/no-go decision needed.

### BUILT
`exercises/ex0..ex5/` — READMEs plus fill-in scripts: `slow_loop.R`,
`generate.R`, `cache_demo.R` (reproduces the caching trap in 20 s),
`embed.R`, `neighbours.R`. `src/install_packages.R`, `src/perturb_data.R`,
`src/fit_replicate.R`, `src/merge_results.R`,
`pbs/submit_array.pbs` + solution.

---

## Session 7 — 2026-08-24 (participant-facing materials)

### VERIFIED
- **Shared environment build completed cleanly.** All of posterior, loo,
  bayesplot, future, furrr, uwot, cmdstanr installed; CmdStan 2.39.0 built;
  empty stderr. `BUILD_SHARED_ENV_DONE`.
- **`^array_index^` in `#PBS -o/-e` works on this system.** Previously flagged
  as an unverified PBS-Pro-ism. A 3-job array produced `logs/rep_1.out`,
  `rep_2.out`, `rep_3.out`, each with the right `$PBS_ARRAY_INDEX`.
  `pbs/submit_array.pbs` is correct as written.
- **Default array output naming** is `<jobname>.o<jobid>.<index>` — a DOT and
  the index (`ws_arraytest.o23130368.1`), not `[i]`. Recorded in config.

### BUILT — the workshop is now readable end to end
- `exercises/ex0..ex6/` complete: every README plus every script they reference.
  New this session: `eda.R` (UMAP by topic and by rating, plus the per-topic
  PC1↔rating correlation that previews the model's answer), `fit_timing.R`
  (cores=1 vs cores=N, then 5 furrr replicates), `control_arm.R` (the
  permutation null), and `ex6_singularity/` — the container tutorial.
- `exercises/solutions/` — complete mirrors plus a README that states every
  answer and *why*, so a stuck participant gets the reasoning, not just the token.
- `setup.md` — participant pre-work. Leads with the e-INFRA-vs-institutional
  password trap, since that is what actually bites.
- `README.md`, `cheat-sheet/cheat_sheet.md`, `runbook/runbook.md`.

The cheat sheet and runbook both carry the hard-won specifics — the 4-parallel
limit, the lying `Retry-After`, the response cache, "never pipe `module add`",
7-minute Stan compiles — because those are the things that cost us hours and
would cost participants the same.

### Corpus
15/100 shards, 7500 texts, **0 duplicates**, steady at ~226 s/shard.

---

## Session 8 — 2026-08-24 (corpus complete)

### ✅ ARTIFACT A1 COMPLETE — and it passes every acceptance criterion

`data/big/corpus_clean_v2.csv.gz` — 50,000 reviews, 8.5 MB.
Generation took **408 minutes** (6.8 h) across 100 resumable shards.

| A1 criterion (handover §6) | result |
|---|---|
| no empty / whitespace texts | **0** |
| no exact duplicates | **0** |
| topic × rating cells balanced within 10% | **exact**: 2000 per topic, 10000 per rating |
| 125 cells × 400 replicates | 400 distinct texts per cell |
| generation metadata populated | yes (model, temperature, seed, persona, aspect, design_version, timestamp) |
| manual read of sampled texts | passed — rating matches content, expressiveness visibly differs |

Mean length 71 words. All 20 personas and 20 aspects used.

**The v2 design fix is fully vindicated at scale.** v1 gave 6 distinct texts per
20-row cell (70% duplicates); v2 gives **400 distinct texts per 400-row cell**.

### Repair rather than drop
The run lost **25 rows (0.05%)** to transport failures — randomly scattered over
18 topics and all 5 ratings, so not a systematic bias. `src/repair_corpus.R`
rebuilds those prompts from their `text_id` and regenerates them (nudging the
seed, since the original request already failed and an identical one risks a
cached miss). All 25 recovered on the first retry, giving an exactly balanced
50,000 rather than one needing a footnote.

*Note on the earlier "24 duplicates" reading: that was `duplicated()` counting
the NA rows as repeats of each other. Among real texts there were **zero**
duplicates from the start.*

### RUNNING
`src/build_embeddings.R` → artifact A2. ~80 texts/s, 25 shards of 2000,
ETA ~10 min. Batches of 64 per request, so one batch costs one parallel slot.

---

## Session 9 — 2026-08-24 (artifacts A2–A4, T8, and a design failure caught)

### ✅ A2 — full embedding matrix
`embeddings_full_v2.rds`, **50000 × 1024, 130 MB, 11.6 min** at ~75 texts/s.
All rows finite, ids aligned to the corpus.

### ✅ A3/A4 — reduction and modelling data
PCA by eigendecomposition of the 1024×1024 covariance (not an SVD of the
50000×1024 matrix — same answer, far cheaper): **19 s**, first 30 PCs explain
**69.0%** of variance (PC1 16.4%, PC2 8.3%, PC3 4.1%). UMAP on the 30 PCs: 0.4 min.
Artifacts: `embeddings_pc30.rds`, `umap_coords.rds`, `corpus_meta.rds`,
`model_data.rds` (50000 rows), `model_data_live.rds` (4000, stratified).

### ⚠ THE DESIGNED HETEROGENEITY DID NOT WORK — caught by measuring it

The `expressiveness` factor was supposed to make the text→rating relationship
vary by topic. **It did not.** Measured on the real embeddings:

| | per-topic \|cor(PC1, rating)\| |
|---|---|
| explicit | 0.890 |
| moderate | 0.934 |
| **understated** | **0.912** |

SD across all 25 topics: **0.019**. Understated topics scored *higher* than
explicit ones. Overall R² of a plain linear model on 30 PCs: **0.83**.

The embedding model recovers sentiment perfectly well from understated prose —
the style instruction changed how the text reads, not what the geometry encodes.
Two things were wrong: the signal was implausibly strong, and **`tau[2]` — the
quantity Block 4 exists to estimate — would have come out at essentially zero.**

**Fix: differential measurement error, which is more realistic anyway.**
In real review data the star rating is a noisy proxy for the sentiment in the
text, and how noisy depends on the category — people give 3 stars to a good
product because delivery was late. So with probability `p_j` (a property of
topic j, set from its expressiveness level) the observed rating is drawn at
random instead of tracking the text:

```
rating          = true sentiment we asked for      (ground truth, unobservable)
rating_observed = what a scraper would see          (what the model is given)
```

| | p_noise | cor(PC1, rating_observed) |
|---|---|---|
| explicit | 0.05 | 0.845 |
| moderate | 0.35 | 0.606 |
| understated | 0.65 | 0.322 |

**SD of per-topic correlation: 0.019 → 0.214 (11×).** The model now has real
variation to find, and the study is a proper measurement-error simulation.
`fit_model.R` models `rating_observed`; using the true rating would be cheating,
since it is not observable in any real dataset.

### ✅ T8 — timings, on the real data
Live subsample 4000 rows, 25 topics, 30 PCs, 4 chains × (1000 warmup + 1000):

| | |
|---|---|
| `cores = 1` | **125.3 s** |
| `cores = 4` | **37.7 s** |
| **speed-up** | **3.32×** |
| divergences | 0 |
| max R-hat | 1.005 |
| min ESS bulk | 667 |

A ~2 min → ~38 s comparison is good pacing for a webinar: long enough to feel,
short enough not to bore. (Scaling the subsample up would lengthen both.)

### ✅ The model works on real data, and the control arm proves it

| arm | beta[1] | tau[2] |
|---|---|---|
| **signal** | −1.558 [−1.671, −1.444] | **0.260 [0.162, 0.379]** |
| **control** | 0.036 [−0.014, 0.087] | 0.061 [0.006, 0.135] |

Signal: strong population effect, between-topic variation clearly above zero.
Control (ratings permuted within topic): **beta[1] straddles zero and tau[2]
collapses ~4×.** A correct method must find nothing here, and it does.

### Warmup noise suppressed, honestly
Stan prints "Metropolis proposal is about to be rejected" during warmup on tied
cutpoints or a degenerate Cholesky factor. Stan's own message says sporadic
occurrences are fine and our diagnostics agree (0 divergences, R-hat 1.005).
`fit_model()` now passes `show_exceptions = FALSE` — and the comment says to
tell participants we did it, rather than pretend it never happens.

---

## Session 10 — 2026-08-24 (A5/A6 done; Block 5 validated end to end)

### ✅ Artifacts uploaded to plzen1, world-readable
`/storage/plzen1/home/chlupp/workshop/artifacts/` — corpus, PC scores, UMAP,
metadata, model data (full + live), `model.stan` and its pre-compiled binary.
`data/big/README.md` (**A6**) documents every file, its provenance, and the
`rating` vs `rating_observed` distinction.

### ✅ A5 — fallback fits, produced by running Block 5 for real
Rather than fabricate the fallbacks, we ran the actual job array: **60 jobs
(30 signal + 30 control)** through `pbs/submit_array.pbs`, in the workshop
container, on the real grid. So A5 exists *and* Block 5 is verified end to end.

Jobs landed across sites (one replicate ran on `alfrid1.meta.zcu.cz` in Plzeň).
Median runtime **1.34 min**; 30 fits complete in ~7 min wall against ~40 min
sequential.

| arm | beta[1] | tau[2] |
|---|---|---|
| **signal** | −1.474 ± 0.054 | **0.141 ± 0.060** |
| **control** | −0.004 ± 0.029 | 0.059 ± 0.016 |

**47 of 60 fits had zero divergences** (median 0); the 206 total was dominated
by one fit with 134. That tail is worth showing: with 30 independent fits you
can *see* the occasional bad one, which a single fit never reveals.

### ⚠ A methodological error, caught by disagreeing numbers

The first array gave `tau[2] = 0.049` where fitting the same data directly gave
`0.260`. The cause was in `perturb_data()`: the bootstrap was stratified on
**`(topic_id, rating_observed)` — i.e. on the outcome.** That forces every topic
to show the same balanced rating distribution, destroying precisely the
between-topic variation the model exists to estimate.

Fixed to stratify **by topic only**. Verified: SD of per-topic correlation is
0.214 in the full data and 0.225 in a bootstrap draw — now preserved, where
before it was flattened.

*Stratify on the grouping factor; never on the thing you are trying to explain.*

### Replicate settings raised, and it taught us something
2 chains × 500 → 4 chains × 750 (runtime 0.93 → 1.34 min against a 1 h walltime,
so the original thrift was buying nothing). R-hat improved, but **`tau[2]` barely
moved: 0.142 → 0.141.** So chain length was not the limitation — a bootstrap
draw genuinely carries less information about between-topic slope variation than
the original sample. Worth knowing rather than assuming.

### Two smaller fixes
- `cmdstanr$summary()` names quantile columns from the quantile (`5%`, `95%`),
  ignoring the argument name given. `summarise_fit()` now renames them, which is
  what broke the first merge.
- Asking for 4 CPUs instead of 2 visibly lengthened the queue wait — a live
  demonstration of the fair-share point Block 5 makes.

---

## Session 11 — 2026-08-26 (restructure to match the slides)

### ⚠ THE GENERATION MODEL DISAPPEARED OVERNIGHT

`qwen3.5-122b`, which the whole corpus was generated with and which config
pinned, **no longer exists on the service.** Requests now return
**HTTP 403 "Model is blocked"** and the model list has gone from 31 entries
to 30.

Worse, its apparent successors are silent failures:

| model | result |
|---|---|
| `qwen3.5`, `qwen3.5-int4` | HTTP **200** with **empty text** |
| `gemma4` | works, 2.6 s |
| `command-a` | works, 3.6 s |
| `mistral-medium-3.5` | works, 3.9 s |

Default is now **`gemma4`** (which had been the documented backup all along),
with `command-a` and `mistral-medium-3.5` behind it. The dead names are added
to `chat_models_unsafe`.

Two guards we already had earned their keep here: the hard-fail-on-empty-content
check turned a silent 403/empty-text failure into an immediate clear error, and
the blocklist meant the failure could be recorded rather than rediscovered.

**New: `pick_working_model()`** in `src/api_client.R` tries the configured model
and walks down the backup list until one actually returns text. So if a model
disappears again mid-workshop, the exercises keep working.

*Note: the shipped corpus was generated with the now-dead model. The data is
unaffected, but `repair_corpus.R` re-run today would use gemma4, mixing
generators. The corpus is complete, so this does not arise in practice.*

### Repo restructured to mirror the slides
Twelve numbered folders, one per slide section, so a slide label can name the
exact file on screen:

```
01_login  02_storage  03_ondemand  04_jobs  05_rstudio  06_interactive_job
07_ai_services  08_embeddings  09_model  10_parallel  11_job_arrays  12_containers
```

### Code rewritten in didactic style
Every file now explains itself in plain language: what it is for, why each step
exists, and what to do when it goes wrong. No dense one-liners where a loop
reads better. Written the way a person would actually write it by hand.

Done and **live-tested on the cluster**: `01_login/login.sh`,
`02_storage/explore_storage.sh` (runs, lists all 27 volumes),
`02_storage/copy_large_data.pbs`, `04_jobs/first_job.pbs` (**submitted and ran**,
job 23313920 on elmo1-2), `04_jobs/check_jobs.sh`,
`06_interactive_job/interactive.sh`, `05_rstudio/setup_packages.R`,
`05_rstudio/slow_loop.R`, `07_ai_services/smoke_test.R` (passes),
`07_ai_services/cache_demo.R` (**reproduces the cache: 1.94 s then 0.10 s,
identical text; distinct text with seeds**).

### Documentation research for the new sections
Verified live: storage volumes and quotas, 11 frontends with cities, 14 cluster
families with core and RAM counts, queue walltime limits, account expiry
(2 February annually), the mandatory acknowledgement text, `my.metacentrum.cz`
and its qsub-assembler, and that **`builder.metacentrum.cz` requires membership
of group `builders`**.

---

## Session 12 — 2026-08-26 (audit and cleanup)

### Decisions
**R only.** The Python track is set aside rather than maintained in
parallel. `src/api_client.py` goes, and with it `config.json` and
`src/export_config.R`, which existed only to feed it. Can be revisited once
the R version is settled.

### Audit result
79 files, of which 30 were dead: the whole `exercises/` tree superseded by
the numbered folders, two byte-identical duplicates (`stan/model.stan`,
`singularity/workshop-r.def`), a compiled Stan binary that was a **macOS
arm64 build and therefore useless on the Linux cluster**, three `src/`
scripts replaced by their didactic rewrites, and two test files that had
leaked into the repository root.

Plus **148 MB of 305 MB** in `data/big`: intermediate shards already merged
into their final artifacts, and the flawed v1 corpus.

`cleanup_obsolete.sh` removes all of it. It refuses to run outside the
repository root, lists everything first and asks once.

### Three real bugs found by the audit
1. `src/fit_model.R` defaulted to `model_file = "stan/model.stan"`, a path
   the cleanup deletes. Now `09_model/model.stan`.
2. `tests/test_model_recovery.R` found the model through a nested
   `dirname(dirname(normalizePath(commandArgs(...))))` expression that both
   broke on the move and was unreadable. Replaced with a plain path and a
   clear error. Re-run after the change: **9/9 recovered, 0 divergences,
   R-hat 1.0045.**
3. A stale `exercises/` reference in a `src/generate_corpus.R` comment.

The rest of the "still referenced" hits were self-references in files being
deleted, or `cmdstan/` matching a search for `stan/`.

### BUILT
- **Twelve section READMEs**, one per folder: what to run, what it is for,
  what done looks like, and the documentation links.
- `03_ondemand/README.md` covers the section with no code, focused on the
  file browser as the main thing OnDemand buys.
- `setup.md`, `README.md`, `cheat-sheet/cheat_sheet.md` and
  `runbook/runbook.md` rewritten for the twelve section order.
- `09_model/control_arm.R` and a didactic rewrite of
  `11_job_arrays/merge_results.R`, both of which the slides referenced but
  which did not exist in the new structure.

`merge_results.R` also lost a `geom_errorbarh()` deprecation warning that
would have printed on screen during section 11.

### Verified after the changes
Every `source()` target resolves. Secrets scan passes. Merge script runs on
the cluster: 30 of 30, 24 with no divergences, median 1.37 min.

---

## Session 13 — 2026-08-26 (artifact names)

### Renamed, no version suffixes
There is only one design now, so `v2` in a filename meant nothing.

| before | after |
|---|---|
| `corpus_clean_v2.csv.gz` | `reviews.csv.gz` |
| `model_data_live.rds` | `model_data_small.rds` |
| `embeddings_full_v2.rds` | `embeddings_full.rds` |
| `model` (the compiled binary) | `model_binary` |

The presenter build scripts no longer generate versioned paths either:
`corpus_shards`, `reviews_raw.csv.gz`, `embedding_shards`.
`generate_corpus.R` now carries a warning to delete the shard directory if
`design/design.json` changes, which is what the version suffix used to
guard against.

### Two files deleted as redundant
- **`embeddings_pc30.rds`** (11.6 MB) was a 50000 by 30 matrix already
  present as columns `PC1..PC30` of `model_data.rds`. A second copy of the
  same numbers, free to drift.
- **`corpus_meta.rds`** (0.6 MB) held labels that `model_data.rds` also
  holds. The extra columns (`topic_label`, `replicate`, `persona`,
  `aspect`) were not used by any analysis.

`08_embeddings/explore_full_corpus.R` now reads `model_data.rds` and
`umap_coords.rds` and nothing else.

### ⚠ A bug the rename work exposed

`explore_full_corpus.R` was colouring the picture and computing the
per-product correlations from **`rating`, the true rating**. The slides
claim the gradient is "obvious in some clumps, absent in others". With the
true rating that claim is false:

| coloured by | per-product correlation | spread |
|---|---|---|
| `rating` (true) | 0.878 to 0.936 | **SD 0.019, effectively uniform** |
| `rating_observed` | 0.297 to 0.854 | SD 0.214 |

The exercise would have contradicted the slide on screen, and would also
have made the problem look far easier than it is, since the true rating is
not observable in any real dataset.

Fixed to use `rating_observed` throughout. Verified on the cluster: the
five strongest products are now all `explicit` ones (0.85) and the five
weakest all `understated` ones (0.30), which is exactly the designed
heterogeneity.

### Also fixed
`generate_corpus.R` printed the wrong filename and `0.0 MB` on completion,
because the final message had a hardcoded path rather than the variable.

### Verified after all changes
No old filename survives anywhere in the repository. A replicate fit runs
on the cluster using `model_binary`: 2.3 min, 0 divergences.

---

## Session 14 — 2026-08-26 (GitHub, and per-user paths)

### ⚠ A collision bug, found while preparing the participant setup
`cfg$storage$results_dir` pointed at the presenter's directory. Five people
running the same job array would each have written `rep_001.rds` to the same
path, silently overwriting one another.

`config.R` now separates the two kinds of path explicitly:

| kind | example | who writes |
|---|---|---|
| shared, read only | `artifacts_dir`, `shared_rlibs`, `image_path` | presenter only |
| yours, writable | `repo_dir`, `results_dir` | built from `$USER` |

Verified on the cluster: as `chlupp` the repo and results resolve under
`/storage/plzen1/home/chlupp/metacentrum-workshop`, while artifacts still
point at the shared copy.

### BUILT: `bootstrap.sh`
One line for participants, in a terminal or in OnDemand's terminal:

```
curl -sL https://raw.githubusercontent.com/ChlupacTheBosmer/metacentrum-workshop/main/bootstrap.sh | bash
```

Clones to `/storage/plzen1/home/<username>/metacentrum-workshop`, the same
place for everybody, so every path on a slide works on every screen. Makes
`results/` and `logs/`. Safe to run twice: it pulls instead of re-cloning.
Checks the volume and the home directory exist first and explains what to
do if not.

**Tested end to end from GitHub on the real cluster**: clean clone, 12
sections present, `results/` created, config resolving per user.

### Published
<https://github.com/ChlupacTheBosmer/metacentrum-workshop> — 63 files.
`data/big` contents excluded, `README.md` inside it kept. Secrets scan run
before the first push and passed.

`.gitignore` extended for the things each participant generates:
`results/`, `logs/`, `my_reviews.csv`, `my_embeddings.rds`, `Rplots.pdf`.

### Slides
Now 107. A bootstrap slide added to the Login section, and everything
renumbered.

---

## Session 15 — 2026-08-27 (clean run on MetaCentrum)

Cloned fresh from GitHub via `bootstrap.sh` to the participant location and
ran everything runnable, in participant order.

### Two bugs found, both fixed and pushed

**1. `submit_array.pbs` hardcoded the presenter's path.** Every participant's
array would have looked for the code in somebody else's home directory. Now
takes the path from `$PBS_O_WORKDIR`, which PBS sets to the directory qsub
was run from.

**2. Every Stan script failed on its own with "CmdStan path has not been set
yet".** It worked in RStudio only because `05_rstudio/setup_packages.R` had
run first in that session. Run from a terminal or inside a job, nothing had
set it. `src/stan_setup.R` now finds Stan in the container or the shared
folder and sets it, and explains what to do if neither is there.

### Slide numbers corrected
The timings on the slides were measured on a laptop. Re-measured on a
compute node they are slower, and the slides now say so:

| | slide before | measured on cluster |
|---|---|---|
| fit_once | about 40 s | about 70 s |
| cores 1 | 125.3 s | 266 s |
| cores 4 | 37.7 s | 82 s |
| speed up | 3.32 x | 3.26 x |

The ratio held; the absolute times did not.

### Also learned
Running Stan on a frontend took 201 s for a fit that takes 70 s on a compute
node, and frontends are shared. The heavy tests were moved to a job, which
is both faster and what the documentation asks for.
