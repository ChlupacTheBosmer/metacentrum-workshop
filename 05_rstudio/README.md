# 5. RStudio

**Goal:** get RStudio running on a compute node, with the packages available.

## Start a session

In OnDemand: **Interactive Apps**, then **RStudio**.

| field | value |
|---|---|
| CPUs | 4 |
| Memory | 16 GB |
| Walltime | 8 hours |

Then **Launch**. It says Queued, then Running.

That form is a job request. Launch means submit. This is section 4 again,
with a form instead of a script.

## Then, in the R console

```r
source("05_rstudio/setup_packages.R")
```

The plain R on MetaCentrum has almost no packages. Installing them
yourself takes between ten minutes and an hour and sometimes fails. For
this workshop they are installed already, in a shared folder. That script
points R at it. Nothing is compiled.

## Something slow

```r
source("05_rstudio/slow_loop.R")
```

Write the time down.

Then answer this: did any of the 2000 repeats need the answer from
another one?

## Done when

`setup_packages.R` prints `ok` for every package, and a Stan version.

## Links

- <https://docs.metacentrum.cz/en/docs/graphical/ondemand>
- <https://docs.metacentrum.cz/en/docs/software/install-software>
