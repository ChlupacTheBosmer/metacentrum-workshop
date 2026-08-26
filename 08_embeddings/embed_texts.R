# ============================================================
#  08_embeddings/embed_texts.R
#  Turning text into numbers
# ============================================================
#
#  WHAT AN EMBEDDING IS
#
#  A second model reads a piece of text and gives back a list of
#  numbers. Here it is 1024 numbers per review.
#
#  The only property that matters: texts that mean similar things
#  get similar numbers. Two reviews that both complain about
#  battery life end up close together.
#
#  That is all it is. Once you have the numbers you are back on
#  familiar ground: it is a matrix, and every method you already
#  know works on it.
#
# ============================================================

source("config.R")
source("src/api_client.R")

library(readr)


# ------------------------------------------------------------
# STEP 1. Load the reviews you made earlier
# ------------------------------------------------------------

my_reviews <- read_csv("my_reviews.csv", show_col_types = FALSE)

cat("Loaded", nrow(my_reviews), "reviews.\n\n")


# ------------------------------------------------------------
# STEP 2. Send the text to the embedding model
# ------------------------------------------------------------
#
# embed() takes a plain vector of text and gives back a matrix:
# one row per review, 1024 columns of numbers.
#
# It sends them in batches of 64. One batch is one request, no
# matter how many texts are in it, so batching is what makes this
# fast. Sixty reviews take about a second.

cat("Sending the text to the embedding model.\n")

time_before <- Sys.time()

embedding_matrix <- embed(my_reviews$text)

time_after <- Sys.time()
seconds <- as.numeric(difftime(time_after, time_before, units = "secs"))

cat("Done in", round(seconds, 1), "seconds.\n\n")


# ------------------------------------------------------------
# STEP 3. Look at what came back
# ------------------------------------------------------------

cat("The matrix has", nrow(embedding_matrix), "rows and",
    ncol(embedding_matrix), "columns.\n")
cat("One row per review. One column per number.\n\n")

# A quick sanity check. If any number is missing or infinite,
# something went wrong and everything downstream will be strange.
all_numbers_fine <- all(is.finite(embedding_matrix))
cat("Every value is a proper number:", all_numbers_fine, "\n\n")

# Show the first few numbers of the first review, just to make it
# concrete. There is nothing meaningful in any single number.
cat("The first 8 numbers of review 1:\n")
cat(round(embedding_matrix[1, 1:8], 3), "\n\n")


# ------------------------------------------------------------
# STEP 4. Save
# ------------------------------------------------------------
#
# We save the numbers and the labels together in one file, so
# they cannot drift apart. saveRDS writes a single R object to
# disk exactly as it is.

saveRDS(
  list(embeddings = embedding_matrix, reviews = my_reviews),
  "my_embeddings.rds"
)

cat("Saved to my_embeddings.rds\n")
