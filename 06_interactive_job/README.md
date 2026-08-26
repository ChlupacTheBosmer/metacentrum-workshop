# 6. Interactive job

**Goal:** get a terminal on a compute node.

## The difference

| | |
|---|---|
| Normal job | runs a script, output read afterwards |
| Interactive job | a terminal on a compute node, typed into live |

## Run

```bash
bash 06_interactive_job/interactive.sh
```

It prints the command and explains each part. Then type the command
yourself:

```bash
qsub -I -l select=1:ncpus=4:mem=8gb:scratch_local=10gb -l walltime=02:00:00
```

The prompt hangs while the scheduler looks for a machine. When it starts,
the machine name changes, for example from `zenith` to `zenon23`.

`exit` gives the machine back. Do that as soon as you are finished.

## When to use one

- copying large amounts of data, which is not allowed on a frontend
- trying commands before writing them into a script
- installing or compiling something
- running R by hand on something bigger than a laptop

## Software modules

```bash
module avail r/                         list R versions
module add r/4.5.1-gcc-10.2.1-zmneq6c   load one
module list                             what is loaded
```

**Never pipe `module add` into anything.** It runs in a subshell and the
change is lost, which produces a confusing "command not found".

## Done when

`hostname` inside the job shows a compute node, not the frontend.

## Links

- <https://docs.metacentrum.cz/en/docs/computing/run-basic-job>
- <https://docs.metacentrum.cz/en/docs/software/modules>
