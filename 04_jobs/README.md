# 4. Jobs

**Goal:** understand what a job is, and send one.

## The idea

The frontend does not do the computing. It takes a request and passes it
to a scheduler, which finds a free machine and runs the work there.

```
login  ->  frontend  ->  scheduler  ->  compute node
```

That request is a **job**. It carries a script plus a note saying how much
hardware it needs and for how long.

## Run

```bash
qsub 04_jobs/first_job.pbs
```

It prints a job number. Then:

```bash
bash 04_jobs/check_jobs.sh
```

## The four commands

```bash
qsub script.pbs        send a job
qstat -u $USER         list jobs
qstat -x -u $USER      include finished ones
qdel 23130368          delete a job
```

States: `Q` queued, `R` running, `F` finished.

## Where the output goes

Two files appear in the directory you submitted from, once the job ends:

```
my_first_job.o23130368     what it printed
my_first_job.e23130368     errors
```

## Asking for resources

```
#PBS -l select=1:ncpus=1:mem=1gb:scratch_local=1gb
#PBS -l walltime=00:05:00
```

Walltime is a hard limit: the job is killed at the end of it. But asking
for far more than needed also makes you wait longer to start, because a
long slot is harder to find.

**Do not name a queue.** It is chosen from the walltime you ask for.

## Done when

`cat my_first_job.o*` shows output from a machine that is not the frontend.

## Links

- <https://docs.metacentrum.cz/en/docs/computing/run-basic-job>
- <https://my.metacentrum.cz> live view of jobs, queues and machines
- <https://my.metacentrum.cz/qsub-assembler> builds a qsub command for you
