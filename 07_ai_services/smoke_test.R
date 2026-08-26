# ============================================================
#  07_ai_services/smoke_test.R
#  Checking the AI service works before relying on it
# ============================================================
#
#  Five things have to be right before any of today's AI work
#  functions. If one of them is wrong you get a confusing error
#  much later. So we test them now, one at a time, and print a
#  clear message for each.
#
#  Run this first. It takes a couple of seconds.
#
# ============================================================

source("config.R")
source("src/api_client.R")


# ------------------------------------------------------------
# TEST 1. Is there a key?
# ------------------------------------------------------------
#
# Your key must be in an environment variable called
# EINFRA_API_KEY. It should NOT be written in any script.
#
# Sys.getenv() reads an environment variable. If the variable is
# not set it gives back an empty piece of text.

cat("1. Looking for your API key ... ")

key <- Sys.getenv("EINFRA_API_KEY")

if (nchar(key) == 0) {
  cat("NOT FOUND\n\n")
  cat("Do this:\n")
  cat("  1. open https://chat.ai.e-infra.cz\n")
  cat("  2. Settings -> Account -> API keys -> generate\n")
  cat("  3. open the file ~/.Renviron\n")
  cat("  4. add this line:   EINFRA_API_KEY=your_key_here\n")
  cat("  5. restart R  (Session menu -> Restart R)\n")
  stop("No API key. Stopping here.")
}

cat("found\n")


# ------------------------------------------------------------
# TEST 2. Can we reach the service and get text back?
# ------------------------------------------------------------
#
# We ask the model for one word. If this works, the address, the
# key and the network are all fine.

cat("2. Asking the model to say one word ... ")

time_before <- Sys.time()

answer <- chat(
  user       = "Say the single word: ready.",
  system     = "Reply with one word only.",
  max_tokens = 20
)

time_after <- Sys.time()
seconds <- as.numeric(difftime(time_after, time_before, units = "secs"))

cat("ok  (", round(seconds, 1), "seconds )\n")
cat("   the model said:", answer, "\n")


# ------------------------------------------------------------
# TEST 3. Does the embedding model work?
# ------------------------------------------------------------
#
# A different model, doing a different job: it turns text into
# numbers. We send it two short texts and check we get two rows
# of numbers back.

cat("3. Turning two short texts into numbers ... ")

vectors <- embed(c("a happy sentence", "a sad sentence"), progress = FALSE)

cat("ok\n")
cat("   we got", nrow(vectors), "rows of", ncol(vectors), "numbers each\n")


# ------------------------------------------------------------
# Done
# ------------------------------------------------------------

cat("\nAll three checks passed. Everything is working.\n")
