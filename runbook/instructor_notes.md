# Instructor notes

Background for the presenter. Nothing here goes on a slide. It is here so
that when somebody asks "why", there is an answer.

Written in the order the slides go.

---

## The study, end to end

### The question

*Does the text of a product review tell you its star rating, and does that
work better for some kinds of product than others?*

### Where the data comes from

We cannot scrape 50000 real reviews in a morning, so a language model wrote
them. For each review we picked a product and a star rating, and asked the
model to write a review that matches.

That sounds circular, and on its own it would be. Two things stop it.

**First, the writing style differs by product.** Each of the 25 products was
assigned a style:

| style | instruction given to the model |
|---|---|
| explicit | state your verdict openly, use plainly evaluative language |
| moderate | mix description with opinion |
| understated | describe factually, let the verdict stay implied |

**Second, and this is the important one, the star rating is deliberately
made unreliable.**

### The two rating columns

The data has two:

| column | meaning |
|---|---|
| `rating` | what we asked the model to write. **Not available in real life** |
| `rating_observed` | what a person scraping a website would actually see |

For a fraction of reviews, `rating_observed` is simply a random number
instead of the true one. That fraction differs by product:

| style | how often the rating is random | how well text predicts it |
|---|---|---|
| explicit | 5 percent | 0.85 |
| moderate | 35 percent | 0.61 |
| understated | 65 percent | 0.32 |

Measured on the real data: for `office_chair` the observed rating matches the
true one **96 percent** of the time. For `bed_sheets` it is **47 percent**.

**Why do this?** Because it is what real review data looks like. People give
three stars to a good product because delivery was late, or five stars to a
mediocre one because it was cheap. How often that happens depends on the
product category.

It also gives the model something real to find. Without it, every product
would look identical (correlations 0.878 to 0.936) and the whole analysis
would have no answer to report.

**Everything is fitted to `rating_observed`.** Using the true rating would
be cheating, since it does not exist outside a simulation.

### Real examples

Same product, two ratings, explicit style (`wireless_headphones`):

> **1 star** "As a daily commuter facing two-hour train rides, I desperately
> needed reliable noise cancellation. These headphones failed miserably
> within weeks, with the battery dying after forty minutes..."

> **5 star** "As a small-business owner constantly juggling calls and
> inventory, these headphones have been a lifesaver..."

The verdict is obvious in both.

Understated style (`bed_sheets`), also 5 star:

> "As a small-business owner, I often face tight deadlines. When a delivery
> of these sheets arrived with a minor seam inconsistency, the team responded
> immediately. They sent replacements without hesitation..."

Notice it never says whether the sheets are good.

### Why each review has a persona and a topic

Every review was generated with a made up reviewer ("a night-shift nurse")
and something to talk about ("how it survived shipping"). These rotate
independently of product and rating.

Two reasons. It stops all 400 reviews of one product coming back identical.
And it makes the corpus look like a real one, where reviewers differ.

---

## What the participants generate themselves

They make **60 reviews**: 3 products they choose, 2 ratings (1 star and 5
star), 10 repeats each. So 3 x 2 x 10.

**This is practice.** It is not used for the analysis. Its purpose is to
show how the API is called and to let them see the cache problem. The 50000
used for the modelling were made in advance, overnight.

---

## Embeddings, PCA and UMAP

### Embedding

A second model reads text and returns **1024 numbers**. Texts that mean
similar things get similar numbers. That is the whole idea. After that it is
a numeric matrix.

### "Reducing" means two different things here

**PCA, 1024 down to 30.** Principal components. Finds the 30 directions in
which the reviews differ most, and describes each review by where it sits
along those 30 instead of all 1024. Keeps 69 percent of the variation. This
is what the model is actually fitted to.

**UMAP, 30 down to 2.** Purely so it can be drawn on a screen. Nothing is
fitted to the UMAP coordinates. It exists to make the plot.

Do not let anyone think the model uses UMAP. It does not.

### "Per product correlation" means

For one product, take all 2000 of its reviews, and correlate the first
principal component of the text with the observed star rating. One number
per product, between 0 and 1.

High means the text predicts the rating well for that product. Low means it
does not. Ours run from 0.32 to 0.85, and that spread is the answer to the
research question.

---

## The model

### In words

For each review, build one number, the score, from its 30 components:

```
score = the average effect of each component
      + how generous this product's reviewers are
      + how strongly THIS product's text predicts its rating
```

A higher score makes a higher star rating more likely.

The three lines are three different things:

1. **The average effect.** How the components relate to the rating, across
   all products together.
2. **This product's own level.** Some products simply get better reviews.
3. **This product's own sensitivity.** For some products the text is a
   strong signal, for others it is weak. **This is what we are measuring.**

### Why not just a normal regression

Because a normal regression gives one answer for everything. It would say
"text predicts rating with strength 0.6" and hide the fact that it is 0.85
for office chairs and 0.32 for bed sheets. That difference is the finding.

### Why ordinal, and why stars are not numbers

Stars are ordered: 5 is better than 4. But the **distance** between them is
not a real quantity.

Going from 1 to 2 stars means "still bad, slightly less so". Going from 4 to
5 means "actually delighted". Those are not the same size of step, but
treating stars as numbers assumes they are, and that an average of 3.5 means
something.

So we use an **ordered** model, which does not assume the gaps are equal. It
estimates where the boundaries between 1 and 2, 2 and 3, and so on actually
sit. Four boundaries for five categories.

If somebody asks the technical name: ordered logistic regression, or
proportional odds.

### Why hierarchical

25 products are not 25 unrelated experiments. They are 25 examples of the
same kind of thing.

A hierarchical model estimates each product separately **and** estimates how
much products vary as a group, then lets the two inform each other. A product
with thin data gets pulled toward the overall pattern instead of trusting its
own noise. This is called partial pooling.

It also gives us the number we actually want: how much products differ. In
the output that is `tau[2]`.

### The two technical details

Both are about making the fit work, not about the science. Say one sentence
and move on unless asked.

**Written a different way.** The same model can be written two ways
mathematically. One of them creates a shape in the parameter space that the
fitting algorithm gets stuck in. We use the other. The name is
"non-centred parameterisation".

**No overall baseline.** The star boundaries already fix the overall level.
Adding a separate baseline term on top would be measuring the same thing
twice, and the model could not tell them apart.

### The recovery test

Before trusting a model on real data, check it can recover an answer you
already know.

We invent a dataset where we chose all the values, fit the model to it, and
see whether it gives those values back. It recovered 9 out of 9 correctly.

If it cannot do that, nothing it says about real data means anything.

### The control arm, and "one extra fit"

The obvious objection: we chose the ratings, so of course they are
recoverable.

So we fit the model a **second time** to deliberately broken data. Same
texts, same products, same number of each rating, but the ratings shuffled
so no review's text matches its own label.

A correct method must now find nothing. It does:

| | effect of text | variation between products |
|---|---|---|
| real data | -1.51 | 0.33 |
| shuffled | 0.00 | 0.06 |

"One extra fit" just means: running the model once more, on the broken data.
It costs a minute and it is the most convincing thing you can show.

---

## Running things

### What `slow_loop.R` does

It resamples a dataset 2000 times and records the median each time. This is
a bootstrap, but the statistics are not the point.

The point is that it takes real time, it does the 2000 repeats one after
another, and **no repeat needs anything from any other one**. That property
is what makes everything later possible.

### The two lines in `setup_packages.R`

```r
.libPaths(c("/storage/plzen1/home/chlupp/workshop/Rlibs", .libPaths()))
```

`.libPaths()` is the list of folders R searches when you call `library()`.
This puts our shared folder at the front of that list, keeping the existing
ones behind it. R then finds our packages first.

```r
cmdstanr::set_cmdstan_path("/storage/plzen1/home/chlupp/workshop/cmdstan/...")
```

Stan is **not an R package**. It is a separate program that R talks to.
cmdstanr is the R package that drives it, and it has to be told where the
program lives.

Both are needed because installing these packages takes 10 to 60 minutes and
sometimes fails. We installed them once, in advance, into a folder everybody
can read.

### Why you must not pipe `module add`

"Piping" means sending the output of one command into another, with `|`:

```bash
module add r/4.5.1 | tail -2      # broken
```

When you pipe a command, the shell runs it in a **subshell**, a separate copy
of itself. `module add` works by changing environment variables, mainly
`PATH`. Those changes happen in the subshell, which then exits, taking the
changes with it.

The result is that the module appears to load, prints its output, and then R
is still not found. We lost twenty minutes to exactly this.

The same applies to anything in `$(...)` or a pipeline. Run `module add` on
its own line.

---

## PBS and job arrays

### What a .pbs file actually is

An ordinary shell script, with extra lines at the top starting `#PBS`.

To the shell those lines are comments and get ignored. To the scheduler they
are the request: how many cores, how much memory, how long.

```bash
#PBS -N myjob
#PBS -l select=1:ncpus=4:mem=8gb:scratch_local=4gb
#PBS -l walltime=01:00:00

cd "$PBS_O_WORKDIR"
Rscript my_script.R
```

`qsub myjob.pbs` hands it to the scheduler. The scheduler finds a machine
with 4 free cores and 8 GB, copies your job there, and runs the script.
Anything the script prints is saved to a file back in the directory you
submitted from.

You are not logged in to that machine and you do not watch it run. You get
the output afterwards.

### What `-J` does

```bash
qsub -J 1-30 script.pbs
```

Starts **the same script 30 times**, on up to 30 different machines. Each
copy is told which one it is: the first is told 1, the second 2, and so on.

The script reads that number from an environment variable:

```r
my_number <- as.integer(Sys.getenv("PBS_ARRAY_INDEX"))
```

and uses it to decide which of the 30 samples to work on. The number also
sets the random seed, so job 7 always produces exactly the same sample.

That is the entire mechanism. One script, thirty numbers.

### MPI, and why we do not need it

Some computations cannot be split into independent pieces. In a weather
model, each machine simulates part of the atmosphere and must exchange
values with its neighbours at every timestep. Fluid dynamics is the same.

**MPI** (Message Passing Interface) is the standard system for that
exchange. Code has to be written specifically for it, and it is a large
amount of work.

Our 30 fits never need anything from each other. So none of that applies.

Worth saying out loud, because people assume "using a cluster" means
learning MPI. For this kind of work it does not.

### `^array_index^` in the output paths

```bash
#PBS -o logs/rep_^array_index^.out
```

These sit with the other `#PBS` lines at the top of the file. PBS replaces
`^array_index^` with each job's own number, so the 30 jobs write 30 separate
log files instead of all writing to one.

### What `merge_results.R` does

Each of the 30 jobs wrote one small file containing its own answer. This
script reads all of them, stacks them into one table, saves it, and draws a
plot showing all 30 estimates side by side.

If some jobs have not finished, it says so and merges the ones that have.
Run it again later for the rest.

### "The occasional bad fit"

47 of the 60 fits finished with no warnings at all. The rest produced some,
and one clearly struggled.

This is normal and worth showing. Fitting a model once and getting a clean
result tells you nothing about how often it goes wrong. Fitting it 30 times
shows you the rate.

---

## Containers

### The problem

Software you did not install and do not control:

- the plain R module has no packages
- the RStudio image has some but no Stan
- installing them yourself is slow and can fail
- admins upgrade R, and last year's analysis stops running
- a colleague cannot reproduce your result without your exact versions

### What a container is

One file holding an entire Linux system: R, every package, the compiler, all
at fixed versions. Run it and you get exactly that environment, on any
machine, today or in three years.

It is **not** a virtual machine. It uses the host's kernel, so there is
almost no performance cost.

### Singularity

The system MetaCentrum uses. Now also called Apptainer, same thing.

- an image is one `.sif` file on ordinary storage
- it runs as **your** user, not as root
- it can see your files, so a job reads and writes storage normally

```bash
singularity exec -B /storage image.sif Rscript script.R
```

`-B /storage` makes the shared filesystem visible inside the container.
Without it, the job cannot find your data.

### Why Singularity and not Docker on the cluster

This is the question that gets asked, so it is worth knowing.

| | Singularity | Docker |
|---|---|---|
| needs root | no | yes, in effect |
| processes run as | you | root by default |
| an image is | one file | layers managed by a background service |
| used on MetaCentrum for | PBS jobs | Kubernetes |

Docker was designed for machines you administer yourself. Its daemon runs as
root, and anyone who can talk to it can effectively become root. A shared
academic cluster with thousands of users cannot allow that.

Singularity was written for exactly this situation: no daemon, no root, one
file, and everything inside runs as the user who launched it.

MetaCentrum does run Docker containers, but on **Kubernetes**, which is a
separate service with its own access model. Not in PBS jobs.

### They are compatible

Singularity can build directly from a Docker image, so anything on Docker
Hub is usable:

```
Bootstrap: docker
From: rocker/tidyverse:4.5.1
```

That is the first line of our own definition file.

### Building

Needs `builder.metacentrum.cz` and membership of the group `builders`. Most
accounts have it; if not, one email to meta@cesnet.cz.

Build to a sandbox folder first, then pack it. A failure in the last step of
a sandbox build costs you that step. A failure in the last step of a direct
build costs you everything, and these builds take twenty minutes.
