# ============================================================
#  08_embeddings/nearest_neighbours.R
#  Does the geometry mean anything?
# ============================================================
#
#  We claimed that similar texts get similar numbers. Let us
#  check, by picking one review and finding the three that sit
#  closest to it.
#
#  Then read them. That is the test.
#
# ============================================================

source("config.R")
source("src/api_client.R")


# ------------------------------------------------------------
# STEP 1. Load what we saved
# ------------------------------------------------------------

saved <- readRDS("my_embeddings.rds")

embedding_matrix <- saved$embeddings
my_reviews       <- saved$reviews


# ------------------------------------------------------------
# STEP 2. Choose a review to ask about
# ------------------------------------------------------------
#
# Change this number and run the file again. Try a 1 star review
# and then a 5 star one.

chosen <- 1


# ------------------------------------------------------------
# STEP 3. Measure the distance to every other review
# ------------------------------------------------------------
#
# We use cosine similarity. It measures whether two lists of
# numbers point in the same direction, ignoring how long they are.
#
#      1  means pointing the same way
#      0  means unrelated
#
# For text embeddings this works better than plain distance.

similarity <- cosine_sim(embedding_matrix[chosen, ], embedding_matrix)


# ------------------------------------------------------------
# STEP 4. Find the closest three
# ------------------------------------------------------------
#
# The chosen review is obviously most similar to itself, so we
# push it out of the running by setting its score very low.

similarity[chosen] <- -Inf

# order() gives the positions that would sort the vector.
# decreasing = TRUE puts the biggest first. We take the top three.
closest_three <- order(similarity, decreasing = TRUE)[1:3]


# ------------------------------------------------------------
# STEP 5. Read them
# ------------------------------------------------------------

cat("============================================\n")
cat("THE REVIEW WE ASKED ABOUT\n")
cat("============================================\n")
cat(my_reviews$topic[chosen], "  rating", my_reviews$rating[chosen], "\n\n")
cat(substr(my_reviews$text[chosen], 1, 200), "\n\n")

cat("============================================\n")
cat("THE THREE CLOSEST REVIEWS\n")
cat("============================================\n\n")

for (position in closest_three) {

  cat("similarity", round(similarity[position], 3), " ",
      my_reviews$topic[position], " rating", my_reviews$rating[position], "\n")
  cat(substr(my_reviews$text[position], 1, 200), "\n\n")
}


# ------------------------------------------------------------
# STEP 6. The two questions
# ------------------------------------------------------------

same_topic  <- sum(my_reviews$topic[closest_three]  == my_reviews$topic[chosen])
same_rating <- sum(my_reviews$rating[closest_three] == my_reviews$rating[chosen])

cat("Of the three closest reviews:\n")
cat("  ", same_topic,  "are about the same product\n")
cat("  ", same_rating, "have the same rating\n\n")

cat("Topic is usually easy. The embedding separates espresso\n")
cat("machines from desk lamps without being told.\n\n")
cat("Rating is harder. That is why the rest of the day needs a\n")
cat("model rather than an eyeball.\n")
