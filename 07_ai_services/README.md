# 7. AI services

**Goal:** call the e-INFRA language models from R, and build a dataset.

## Get a key

1. <https://chat.ai.e-infra.cz>, log in with e-INFRA
2. Try the chat once by hand
3. Settings, Account, API keys, generate
4. Put it in `~/.Renviron`:

```
EINFRA_API_KEY=your_key_here
```

5. Restart R: Session menu, Restart R

**Never put the key in a script.** Scripts get shared and committed.

## Check it works

```r
source("07_ai_services/smoke_test.R")
```

Three checks: key present, text model answering, embedding model answering.

## The study

*Does the text of a review carry its star rating, and does that differ
between products?*

Real reviews cannot be scraped this morning, so a model writes them from
a rating we choose. Because we chose it, we know the right answer. That
is what makes this a simulation study.

## Generate

```r
source("07_ai_services/generate_texts.R")
```

3 products, 2 ratings, 10 repeats, so 60 reviews. About 45 seconds.
Edit `my_topics` near the top to choose your own products.

Read a couple afterwards. Does the text match the rating asked for?

## The trap worth seeing

```r
source("07_ai_services/cache_demo.R")
```

The service remembers answers. Ask the same question twice and the same
text comes back, in a tenth of the time. Our first corpus was 70 percent
exact copies because of this, and every other check said it was fine.

The fix is a different `seed` on each request.

**Count duplicates before anything else.**

## Done when

`my_reviews.csv` exists with 60 rows and 0 duplicates.

## Links

- <https://chat.ai.e-infra.cz>
- <https://docs.cerit.io/en/docs/ai-as-a-service/chat-ai>
- <https://docs.cerit.io/en/docs/ai-as-a-service/ai-api>
