# Runbook

Presenter notes. Keep this on a second screen.

Everything checked 26 August 2026 unless marked otherwise.

---

## Paths to have ready

```
OnDemand        https://ondemand.metacentrum.cz
AI chat, key    https://chat.ai.e-infra.cz
Frontend        zenith.metacentrum.cz
Live view       https://my.metacentrum.cz

Shared R packages
  /storage/plzen1/home/chlupp/workshop/Rlibs
Shared Stan
  /storage/plzen1/home/chlupp/workshop/cmdstan/cmdstan-2.39.0
Artifacts
  /storage/plzen1/home/chlupp/workshop/artifacts
Container for PBS jobs
  /storage/plzen1/home/chlupp/workshop/images/workshop-r.sif
```

**The two lines participants need.** Put them in the chat window at the
start of section 5:

```r
.libPaths(c("/storage/plzen1/home/chlupp/workshop/Rlibs", .libPaths()))
cmdstanr::set_cmdstan_path(
  "/storage/plzen1/home/chlupp/workshop/cmdstan/cmdstan-2.39.0")
```

---

## Before starting

```bash
ls /storage/plzen1/home/chlupp/workshop/
```

Five things should be there: `Rlibs`, `cmdstan`, `artifacts`, `images`,
`results`. If they are, the day works.

---

## Order, and what can be cut

Sections build on each other up to 6. After that they are more separable.

| section | can it be cut |
|---|---|
| 1 Login | no, everything follows from it |
| 2 Storage | no, the paths are needed all day |
| 3 OnDemand | no |
| 4 Jobs | no, sections 5, 6 and 11 assume it |
| 5 RStudio | no |
| 6 Interactive job | shorten to a demo if behind |
| 7 AI services | no |
| 8 Embeddings | shorten, the full corpus part is the keeper |
| 9 The model | keep the control arm even if the rest is rushed |
| 10 Parallel | no, it is two commands |
| 11 Job arrays | no, this is the point of the day |
| 12 Containers | can move to a second session |

If the day runs out, stop after 11 and schedule the rest.

---

## When something breaks

| symptom | fix | time |
|---|---|---|
| Cannot log in | e-INFRA password, not university. profile.e-infra.cz | 2 min |
| `.libPaths` line does nothing | check the path with `ls` in the Terminal pane | 3 min |
| Stan wants to compile | not using the prepared binary; check `cfg$storage$artifacts_dir` | 2 min |
| Reviews come back identical | the `seed` argument was dropped. Show `cache_demo.R` | 1 min |
| HTTP 429 storm | concurrency above 2. It self heals, tell them to use 2 | 1 min |
| R session hangs on an API call | old client obeying `Retry-After`. Restart R, re-source | 2 min |
| **A model returns 403 or empty text** | it was removed from the service. `pick_working_model()` falls through to the next one automatically | 1 min |
| Stan will not run in RStudio at all | skip to interpreting the prepared fit, do all fitting in section 11 | 5 min |
| Queue slow in section 11 | merge the prepared results, let their jobs finish later | 2 min |
| OnDemand degraded | the terminal path still works; sections 1, 2, 4, 6, 11 are unaffected | |

---

## Things worth saying, that are true and specific

All of these came out of building this. Each lands better than an
invented example.

- **The quota banner.** brno2 on this account sits at 93 percent. It is a
  real example of the cluster warning before the wall is hit.
- **The 70 percent duplicate corpus.** Every other check passed. Only a
  duplicate count found it. The service caches identical requests.
- **`Retry-After: 1800` is wrong.** Other requests on the same key succeed
  in the same second. A well behaved client freezes for half an hour.
- **More concurrency was slower.** At 3 parallel we generated constant
  429s and paid 8 seconds of backoff each time: 480 seconds per shard.
  At 2 it was 226. Measured.
- **Compiling Stan took 7 minutes. Loading the prepared binary takes 0.32
  seconds.**
- **Never pipe `module add`**, it runs in a subshell and the change is lost.
- **The generation model disappeared two days before the workshop.**
  Monday it answered, Wednesday it returned 403. This is the concrete
  argument for containers, and it is not hypothetical.
- **Four container builds failed** before one worked: a hardcoded version
  path, a fix that used invisible session state, a full disk, and NFS
  being unable to set file ownership.
- **Stratify on the grouping factor, never on the outcome.** Doing the
  latter gave tau[2] = 0.049 where the correct answer was 0.260.

---

## Checkpoints

| after section | everyone should have |
|---|---|
| 1 | a prompt on a frontend |
| 2 | found their home on two different volumes |
| 3 | seen the same directory in the browser and the terminal |
| 4 | one finished job and its output file |
| 5 | RStudio open, `setup_packages.R` all ok |
| 7 | `my_reviews.csv`, 60 rows, 0 duplicates |
| 9 | a fitted model, 0 divergences |
| 10 | two timings |
| 11 | a merged table from 30 machines |
