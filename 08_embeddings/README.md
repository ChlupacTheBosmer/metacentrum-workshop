# 8. Embeddings

**Goal:** turn the reviews into numbers and look at the shape of them.

## What an embedding is

A model reads text and gives back a fixed list of numbers, 1024 of them
here. Texts that mean similar things get similar numbers.

That is the whole idea. After that it is a numeric matrix and every
method you already know applies to it.

## Embed your own

```r
source("08_embeddings/embed_texts.R")
```

60 reviews, about a second. They go in batches of 64, and one batch is
one request no matter how many texts are in it.

## Check the geometry means something

```r
source("08_embeddings/nearest_neighbours.R")
```

Picks one review, finds the three closest, prints them. Read them.

- Same product? Almost always
- Same rating? Less often

Product is the easy signal. Rating is the hard one, which is why the rest
of the day needs a model.

Change `chosen` near the top and run it again.

## The full corpus

```r
source("08_embeddings/explore_full_corpus.R")
```

All 50000 reviews, made overnight with the same scripts:

| | |
|---|---|
| generating | 408 minutes |
| embedding | 12 minutes |
| reducing | 1 minute |

Two pictures come out. Coloured by product there are clear clumps.
Coloured by rating there is a gradient inside each clump, obvious in some
and absent in others.

**That difference is the research question.**

## Done when

Both plots have appeared, and the printed table shows the per product
correlation is not the same for every product.
