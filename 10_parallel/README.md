# 10. One machine, many cores

**Goal:** see what asking for more cores actually buys.

## Why it works

The model is fitted by four chains. Each is a separate exploration from a
different starting point. They never talk to each other while running,
and are only compared at the end.

Because they never talk, they can run at the same time.

## Run

```r
source("10_parallel/compare_cores.R")
```

It fits twice. One argument differs:

```r
fit_model(dat, cores = 1, chains = 4)
fit_model(dat, cores = 4, chains = 4)
```

## Result

| | |
|---|---|
| 1 core | 125.3 s |
| 4 cores | 37.7 s |
| speed up | 3.32 x |

## Why not 4 times

- the slowest chain decides the total
- warm up takes different lengths in each chain
- starting and collecting the chains costs a little

## The limit worth remembering

Four chains means four pieces of work. **Asking for 40 cores would change
nothing at all.**

To go faster than this you need more machines, not more cores. That is
section 11.
