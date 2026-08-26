# Data artifacts

These files are too large for git. They live on shared MetaCentrum storage
and every exercise reads them from there.

```
/storage/plzen1/home/chlupp/workshop/artifacts/
```

## What is here

| file | size | what it is |
|---|---|---|
| `reviews.csv.gz` | 8.5 MB | the 50000 generated reviews, with their labels |
| `model_data.rds` | 12 MB | the same reviews as numbers: labels plus 30 principal components each |
| `model_data_small.rds` | 0.9 MB | a 4000 row subsample, for fitting during a session |
| `umap_coords.rds` | 0.5 MB | 2 coordinates per review, for drawing pictures |
| `model.stan` | 12 KB | the model |
| `model_binary` | 3 MB | the model, already compiled |

`embeddings_full.rds`, the raw 50000 by 1024 matrix, is 130 MB and is kept
only by the presenter. Nothing in the workshop needs it: the 30 principal
components in `model_data.rds` carry what matters.

## Loading them

```r
source("config.R")
artifacts <- cfg$storage$artifacts_dir

reviews <- readRDS(file.path(artifacts, "model_data.rds"))
small   <- readRDS(file.path(artifacts, "model_data_small.rds"))
umap    <- readRDS(file.path(artifacts, "umap_coords.rds"))
```

## The two rating columns

This is the one thing worth reading carefully.

| column | meaning |
|---|---|
| `rating` | what the model was asked to write. The truth. **In a real dataset this does not exist.** |
| `rating_observed` | what somebody scraping a website would actually see |

They differ because a star rating is a noisy record of what the text says.
People give three stars to a good product because delivery was late. How
often that happens was set differently for each product, on purpose.

| product style | how often the rating is noise | resulting correlation |
|---|---|---|
| explicit | 5 percent | 0.85 |
| moderate | 35 percent | 0.61 |
| understated | 65 percent | 0.32 |

**Everything models `rating_observed`.** Using the true rating would make
the problem far easier than it is in real life, and there would be nothing
left for the model to discover: with the true rating every product looks
the same (correlations 0.878 to 0.936), whereas with the observed rating
they genuinely differ (0.297 to 0.854).

That difference between products is the whole question the workshop asks.

## How these were made

All of it by this repository's own scripts, at full size.

| step | script | time |
|---|---|---|
| generate 50000 reviews | `src/generate_corpus.R` | 408 min |
| replace 25 that failed | `src/repair_corpus.R` | seconds |
| turn text into numbers | `src/build_embeddings.R` | 12 min |
| reduce and assemble | `src/build_reduction.R` | 1 min |
| 30 repeat fits | `11_job_arrays/submit_array.pbs` | 2 min each |

Generated 23 and 24 August 2026. Text by `qwen3.5-122b`, which has since
been withdrawn from the service; the current default is `gemma4`.
Embeddings by `mxbai-embed-large`, 1024 numbers per review.

## Quality

| check | result |
|---|---|
| empty reviews | 0 |
| exact duplicates | 0 |
| reviews per product | exactly 2000 |
| reviews per rating | exactly 10000 |

## Licence

Synthetic. No personal data, nothing scraped. Freely shareable.
