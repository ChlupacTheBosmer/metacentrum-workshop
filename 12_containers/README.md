# 12. Containers

**Goal:** understand why containers exist here, and how to build one.

## The problem, met three times today

- the plain R module has no packages at all
- the RStudio image has tidyverse but no Stan
- installing packages takes a long time and can fail

## And a fourth reason

The language model this workshop was built on **disappeared two days
before the workshop**. On Monday it answered normally. On Wednesday it
returned `HTTP 403, model is blocked`.

Software nobody controls locally changes without warning.

## What a container is

One file holding R, every package, and the compiler, at fixed versions.
It runs the same today, next year, and on somebody else's machine. The
same file is used by the RStudio session and by all 30 array jobs.

## The definition file

`12_containers/workshop-r.def`

| section | what it does |
|---|---|
| `Bootstrap`, `From` | what to start from |
| `%post` | commands run while building |
| `%environment` | variables set every time it runs |
| `%test` | runs at the end; failure fails the build |

Two lines worth copying into your own:

- fail the build if a package is missing
- compile and run a tiny Stan model during the build

A container quietly missing a package is worse than no container, because
it will be trusted.

## Building

```bash
bash 12_containers/build_image.sh
```

That prints the steps and explains them. The real commands:

```bash
ssh builder.metacentrum.cz
export SINGULARITY_TMPDIR=/scratch/$USER/tmp
singularity build --fakeroot --sandbox mydir/ workshop-r.def
singularity build --fakeroot workshop-r.sif mydir/
```

**Access:** building needs membership of the group `builders`. Most
accounts have it already. If yours does not, one email to meta@cesnet.cz.

## Four ways it failed for us

1. hardcoded a version number into a path
2. fixed it in R, where the answer was not visible to a fresh session
3. filled the build disk
4. moved the build to network storage, which cannot set file ownership

Build to a sandbox folder first. A failure then costs one step instead of
the whole thing.

## Using it

```bash
singularity exec -B /storage workshop-r.sif Rscript my_analysis.R
```

`-B /storage` matters. Without it the container cannot see the shared
filesystem and the job will insist your data does not exist.

## Links

- <https://docs.metacentrum.cz/en/docs/software/containers>
- ready made images: `/cvmfs/singularity.metacentrum.cz/`
