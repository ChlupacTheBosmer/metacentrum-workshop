# 11. Job arrays

**Goal:** run the same analysis 30 times on 30 machines.

## Do this first, read second

```bash
qsub -J 1-30 11_job_arrays/submit_array.pbs
```

Send it now, then carry on reading while it runs. The queue is not dead
time if it is planned for.

## Why 30 fits

One fit says what this data shows. It does not say how much that would
move if the data had come out slightly differently. So we resample, refit
and repeat, then look at the spread.

Each repeat is independent of the others, which is exactly the property
that makes this easy.

## What `-J` does

```
qsub -J 1-30 script.pbs   ->  30 jobs on up to 30 machines
```

They are identical except for one number. Job 1 sees 1, job 2 sees 2.
The script reads it from `$PBS_ARRAY_INDEX` and uses it to pick its work.

That is the entire mechanism. No MPI, no rewriting of the statistics.

## Watching them

```bash
qstat -t -u $USER      the -t expands all 30
qdel '23156948[]'      delete the whole array, keep the brackets
```

Are all 30 running? Probably not. The scheduler is fitting them into gaps
around everyone else's work.

## Merge

```bash
Rscript 11_job_arrays/merge_results.R signal
```

It tolerates missing repeats on purpose. Run it early and it says
"merged 23 of 30, still waiting on 7". Run it again later.

That is not an error. That is what a cluster looks like.

## Result

| | beta[1] | tau[2] |
|---|---|---|
| real, 30 fits | -1.474 | 0.141 |
| shuffled, 30 fits | -0.004 | 0.059 |

30 fits in parallel: about 7 minutes. One after another: about 40.

## A bonus

47 of 60 fits had no problems. One had 134 divergences. A single fit
never shows you that tail.

## Links

- <https://docs.metacentrum.cz/en/docs/computing/advanced>
