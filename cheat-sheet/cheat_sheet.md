# MetaCentrum cheat sheet

Checked 26 August 2026.

## Addresses

| | |
|---|---|
| OnDemand | `ondemand.metacentrum.cz` |
| AI chat, and where the key comes from | `chat.ai.e-infra.cz` |
| AI API | `https://llm.ai.e-infra.cz/v1` |
| Jobs, queues, machines, quotas | `my.metacentrum.cz` |
| Build a qsub command | `my.metacentrum.cz/qsub-assembler` |
| Password reset | `profile.e-infra.cz` |
| Account status | `perun.e-infra.cz` |
| Docs | `docs.metacentrum.cz` and `docs.e-infra.cz` |
| Support | `meta@cesnet.cz` |

## Frontends

| Brno | `zenith` `skirit` `perian` `oven` |
|---|---|
| Praha | `tarkil` `elmo` `metafzu` |
| Plzeň | `nympha` |
| Liberec | `charon` |
| Průhonice | `tilia` |

```bash
ssh username@zenith.metacentrum.cz
```

The password is the **e-INFRA** one, usually not the university one.

## Storage

```
/storage/<volume>/home/<username>
$SCRATCHDIR                 fast local disk, per job, deleted after
```

One home per volume. They are separate disks.

| volume | quota |
|---|---|
| brno2 | 4.29 T |
| plzen1 | 3.22 T |
| budejovice1 | 3.22 T |
| institute volumes | a few GB |

Quotas are printed at login, and shown at `my.metacentrum.cz`.

**Large copies go in a job, not on a frontend.**

## Jobs

```bash
qsub script.pbs                 send one
qsub -J 1-30 script.pbs         send thirty
qstat -u $USER                  list them
qstat -t -u $USER               expand an array
qstat -x -u $USER               include finished
qdel 23130368                   delete one
qdel '23130368[]'               delete an array
```

States: `Q` queued, `R` running, `F` finished.

Output lands in the submit directory as `name.o<jobid>`.

## A job script

```bash
#!/bin/bash
#PBS -N myjob
#PBS -l select=1:ncpus=4:mem=8gb:scratch_local=4gb
#PBS -l walltime=01:00:00

cd "$PBS_O_WORKDIR"
singularity exec -B /storage image.sif Rscript script.R "$PBS_ARRAY_INDEX"
```

- `$PBS_ARRAY_INDEX` is which job in the array this is
- `-B /storage` or the container cannot see your data
- do not name a queue, it follows from the walltime
- walltime is a hard kill, but over asking makes you wait longer

## Queues

| queue | max walltime |
|---|---|
| `q_2h` | 2 hours |
| `q_2d` | 48 hours |
| `q_4d` | 96 hours |
| `q_1w` | 168 hours |
| `interactive` | 48 hours |

## Interactive job

```bash
qsub -I -l select=1:ncpus=4:mem=8gb:scratch_local=10gb -l walltime=02:00:00
```

## R

```bash
module avail r/
module add r/4.5.1-gcc-10.2.1-zmneq6c
```

**Never pipe `module add`.** It runs in a subshell and the change is lost.

The plain module has no packages. Use the shared library:

```r
.libPaths(c("/storage/plzen1/home/chlupp/workshop/Rlibs", .libPaths()))
cmdstanr::set_cmdstan_path(
  "/storage/plzen1/home/chlupp/workshop/cmdstan/cmdstan-2.39.0")
```

## The AI API

```r
Sys.getenv("EINFRA_API_KEY")     from ~/.Renviron, never in code
chat_many(prompts, seed = seeds) always pass distinct seeds
embed(texts)                     batches of 64, 1024 numbers each
```

Three things that will bite:

- **4 parallel requests per key.** Use 2 in R; httr2 opens more than it says
- **A 429 asks for an 1800 second wait. That is wrong.** Cap your own backoff
- **Identical requests return the identical answer.** Vary the seed or the
  data will be full of duplicates
- **Models come and go.** Ours vanished two days before the workshop

## Containers

```bash
ssh builder.metacentrum.cz                      needs group "builders"
export SINGULARITY_TMPDIR=/scratch/$USER/tmp    local disk, never NFS
singularity build --fakeroot --sandbox dir/ my.def
singularity build --fakeroot my.sif dir/
```

## If X, do Y

| problem | answer |
|---|---|
| A loop takes minutes | more cores on one machine |
| 1000 independent runs | a job array |
| Chains are slow | one core per chain, more buys nothing |
| Package not available | shared library, or a container |
| Stan takes minutes to compile | ship the compiled binary |
| Out of quota | a different storage volume |
| Grid is not enough | IT4Innovations |

## Publications

```
Computational resources were provided by the e-INFRA CZ project
(ID:90254), supported by the Ministry of Education, Youth and Sports
of the Czech Republic.
```
