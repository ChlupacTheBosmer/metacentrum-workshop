# 9. The model

**Goal:** answer the question properly, and check the answer is real.

## The question

*How much does the text to rating relationship vary between products?*

Not whether there is a relationship. There is. The interesting part is
how much it differs, which a single average would hide.

## The model

`09_model/model.stan` is the model, commented line by line. In words:

```
score = average effect of each component
      + this product's own adjustment
      + this product's own extra sensitivity
```

Four choices worth arguing about, all explained in the file:

- **Ordinal outcome.** Stars are ordered but the gaps are not equal, so
  the model estimates the cut points rather than assuming them
- **Hierarchical.** 25 products are not 25 unrelated experiments
- **Non centred.** The obvious form makes a shape the sampler cannot explore
- **No global intercept.** Not identified; the cut points absorb it

The file also lists four things I am **not** certain about. Disagreeing
with one is a good use of a coffee break.

## Is the model right

```bash
Rscript tests/test_model_recovery.R 1500 2
```

Makes data with known answers, fits, checks they come back.
Result: 9 of 9 inside their intervals, 0 divergences, rhat 1.010.

## Fit it

```r
source("09_model/fit_once.R")
```

4000 rows, 25 products, 4 chains, about 40 seconds.

Check **divergences** is 0 and **rhat** is under 1.01 before reading
anything else. If either fails the numbers mean nothing.

`tau[2]` is the answer: how much the effect varies between products.

## The control

```r
source("09_model/control_arm.R")
```

The obvious objection is that we chose the ratings, so of course they can
be recovered. So we shuffle the ratings within each product and fit again.
Same texts, same products, link broken.

A correct method must now find nothing:

| | beta[1] | tau[2] |
|---|---|---|
| real | -1.56 | 0.26 |
| shuffled | 0.04 | 0.06 |

One extra fit, and the most convincing check available.
