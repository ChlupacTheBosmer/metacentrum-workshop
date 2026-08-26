# ============================================================
#  07_ai_services/generate_texts.R
#  Making our own dataset
# ============================================================
#
#  WHAT WE ARE DOING
#
#  We want reviews of products, each with a known star rating.
#  We cannot scrape real ones this morning, so we ask a language
#  model to write them. We choose the rating, it writes the text.
#
#  Because we chose the rating, we know the right answer. That is
#  what makes this a simulation study: later we can check whether
#  our method finds the thing we put there.
#
#  Each of you generates 60 reviews:
#      3 topics  x  2 ratings  x  10 repeats  =  60
#
#  It takes about a minute.
#
# ============================================================

source("config.R")
source("src/api_client.R")
source("src/gen_prompts.R")

library(dplyr)
library(readr)


# ------------------------------------------------------------
# STEP 1. Pick three topics
# ------------------------------------------------------------
#
# There are 25 to choose from. See them all with:
#
#     design <- load_design()
#     sapply(design$topics, function(t) t$topic)
#
# Pick different ones from the person next to you. It spreads the
# load on the service and makes the comparison at the end more
# interesting.

my_topics <- c("espresso_machine", "smartphone", "desk_lamp")


# ------------------------------------------------------------
# STEP 2. Build the instructions
# ------------------------------------------------------------
#
# make_live_prompts() writes out one instruction per review. Each
# instruction names the product, the rating, a made up reviewer,
# and something for them to talk about.
#
# The reviewer and the subject change from one review to the next.
# That is deliberate. It is what stops all 60 coming back the
# same, which is what happened to us the first time. See
# cache_demo.R for the full story.

prompts <- make_live_prompts(my_topics)

cat("Built", nrow(prompts), "instructions.\n\n")
cat("Here is the first one:\n\n")
cat(prompts$user_prompt[1], "\n\n")


# ------------------------------------------------------------
# STEP 3. Send them
# ------------------------------------------------------------
#
# chat_many() sends them a few at a time rather than all at once,
# because the service allows only four of our requests to be in
# flight together.
#
# We also hand it prompts$seed. A seed is a number that goes with
# each request. It makes each one different from the service's
# point of view, so we get 60 fresh reviews instead of a handful
# repeated.

cat("Sending them to the model. Please wait.\n")

time_before <- Sys.time()

review_texts <- chat_many(
  user   = prompts$user_prompt,
  system = prompts$system_prompt[1],
  seed   = prompts$seed
)

time_after <- Sys.time()
seconds <- as.numeric(difftime(time_after, time_before, units = "secs"))

cat("Done in", round(seconds, 1), "seconds.\n\n")


# ------------------------------------------------------------
# STEP 4. Check before saving
# ------------------------------------------------------------
#
# Three things can go wrong. Check all three now, while it is
# still cheap to fix.

n_failed     <- sum(is.na(review_texts))
n_empty      <- sum(!is.na(review_texts) & trimws(review_texts) == "")
n_duplicated <- sum(duplicated(review_texts[!is.na(review_texts)]))

cat("Requests that failed :", n_failed, "\n")
cat("Reviews that are empty:", n_empty, "\n")
cat("Reviews that are exact copies:", n_duplicated, "  <- should be 0\n\n")

if (n_duplicated > 0) {
  cat("Some reviews are identical. That usually means the seeds\n")
  cat("were not sent. Look at step 3 again.\n\n")
}


# ------------------------------------------------------------
# STEP 5. Save
# ------------------------------------------------------------
#
# We keep the labels next to the text. Without them the reviews
# are useless: the whole point is that we know what rating each
# one was written for.

my_reviews <- prompts %>%
  mutate(
    text         = review_texts,
    model        = cfg$ai$chat_model,
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ) %>%
  select(text_id, topic, rating, replicate, persona, aspect,
         text, model, generated_at)

write_csv(my_reviews, "my_reviews.csv")

cat("Saved", nrow(my_reviews), "reviews to my_reviews.csv\n\n")


# ------------------------------------------------------------
# STEP 6. Read a couple
# ------------------------------------------------------------
#
# No automatic check replaces reading the data. Look at a
# one star review and a five star review from the same product.
# Do they match the rating we asked for?

one_star  <- my_reviews %>% filter(rating == 1) %>% slice(1)
five_star <- my_reviews %>% filter(rating == 5) %>% slice(1)

cat("--- a 1 star review of", one_star$topic, "---\n")
cat(one_star$text, "\n\n")

cat("--- a 5 star review of", five_star$topic, "---\n")
cat(five_star$text, "\n")
