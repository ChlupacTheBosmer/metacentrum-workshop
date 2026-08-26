# ============================================================
#  07_ai_services/cache_demo.R
#  Why the same question gives the same answer
# ============================================================
#
#  A WARNING THAT COST US A DAY
#
#  When we built the data for this workshop, the first attempt
#  produced 50000 reviews of which about 70 percent were exact
#  copies of each other.
#
#  Everything else looked fine. No empty rows. Balanced groups.
#  Sensible lengths. Only a duplicate check found it.
#
#  The reason: the service remembers answers. Ask exactly the
#  same question twice and it hands back the stored answer
#  instead of writing a new one. That is sensible for a chat
#  program and a disaster when you are generating data.
#
#  This file shows it happening.
#
# ============================================================

source("config.R")
source("src/api_client.R")

question <- "Write a 40 word customer review of a kitchen scale. The reviewer is satisfied."


# ------------------------------------------------------------
# PART 1. The same question, three times
# ------------------------------------------------------------

cat("============================================\n")
cat("Asking exactly the same question three times\n")
cat("============================================\n\n")

for (attempt in 1:3) {

  time_before <- Sys.time()
  answer <- chat(question, max_tokens = 120)
  time_after <- Sys.time()

  seconds <- as.numeric(difftime(time_after, time_before, units = "secs"))

  # substr() cuts a long piece of text down to its first N letters
  # so the screen stays readable.
  short_answer <- substr(answer, 1, 55)

  cat("  attempt", attempt, ":", round(seconds, 2), "seconds\n")
  cat("    ", short_answer, "...\n")
}

cat("\n")
cat("  Same text every time. And attempts 2 and 3 came back much\n")
cat("  faster, because nothing was actually written.\n\n")


# ------------------------------------------------------------
# PART 2. The same question, with a different seed each time
# ------------------------------------------------------------
#
# A "seed" is just a number you send along with the question.
# It changes the random choices the model makes. It also makes
# the request different, so the stored answer no longer matches
# and the model has to write a fresh one.

cat("============================================\n")
cat("The same question, but with a different seed\n")
cat("============================================\n\n")

for (seed_value in c(11, 22, 33)) {

  time_before <- Sys.time()

  answer <- chat_many(
    user       = question,
    seed       = seed_value,
    max_tokens = 120,
    progress   = FALSE
  )

  time_after <- Sys.time()
  seconds <- as.numeric(difftime(time_after, time_before, units = "secs"))

  short_answer <- substr(answer, 1, 55)

  cat("  seed", seed_value, ":", round(seconds, 2), "seconds\n")
  cat("    ", short_answer, "...\n")
}

cat("\n")
cat("  Different text every time, and all at full speed.\n\n")


# ------------------------------------------------------------
# What to take away
# ------------------------------------------------------------

cat("============================================\n")
cat("The rule\n")
cat("============================================\n\n")
cat("  When you generate data with a language model,\n")
cat("  count your duplicates before you look at anything else.\n\n")
cat("  Every other check we ran said the data was fine.\n")
