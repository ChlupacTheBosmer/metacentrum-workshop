# ============================================================
#  08_embeddings/explore_full_corpus.R
#  Looking at all 50000 reviews at once
# ============================================================
#
#  You made 60 reviews. The full set of 50000 was made in advance,
#  overnight, using the same scripts you just ran.
#
#      generating them took   408 minutes
#      embedding them took     12 minutes
#      reducing them took       1 minute
#
#  That is normal cluster work. The big run happens while you are
#  asleep. The interactive session is where you check the code is
#  right on a small piece first.
#
# ============================================================

source("config.R")

library(dplyr)
library(ggplot2)


# ------------------------------------------------------------
# STEP 1. Load the prepared files
# ------------------------------------------------------------
#
# We do not load the raw 1024 numbers per review. That file is 130 MB
# and nothing here needs it. Two smaller files were worked out from it
# in advance:
#
#   model_data.rds    the labels, plus 30 principal components per
#                     review instead of 1024, keeping most of the
#                     variation
#   umap_coords.rds   2 numbers per review, purely so we can draw a
#                     picture

artifacts <- cfg$storage$artifacts_dir

reviews          <- readRDS(file.path(artifacts, "model_data.rds"))
umap_coordinates <- readRDS(file.path(artifacts, "umap_coords.rds"))

# The 30 components live in columns named PC1 to PC30. Pull them out as
# a plain matrix, which is easier to do arithmetic on.
principal_components <- as.matrix(reviews[, paste0("PC", 1:30)])

cat("Loaded", nrow(reviews), "reviews.\n")
cat("Topics:", length(unique(reviews$topic)), "\n\n")

# ------------------------------------------------------------
# WHICH RATING TO USE
# ------------------------------------------------------------
#
# There are two rating columns and the difference matters.
#
#   rating            what we asked the model to write. The truth.
#                     In a real dataset this does not exist.
#   rating_observed   what somebody scraping a website would see.
#
# They differ because a star rating is a noisy record of what the text
# actually says. People give three stars to a good product because
# delivery was late. How often that happens varies by product.
#
# We use rating_observed everywhere, because it is the only one that
# would be available in real life. Using the true rating would make the
# problem far easier than it really is.


# ------------------------------------------------------------
# STEP 2. Put the pieces in one table
# ------------------------------------------------------------
#
# The three files line up row for row. We glue them side by side
# so ggplot can use them together.

plotting_data <- reviews
plotting_data$UMAP1 <- umap_coordinates[, 1]
plotting_data$UMAP2 <- umap_coordinates[, 2]


# ------------------------------------------------------------
# STEP 3. Colour by product
# ------------------------------------------------------------
#
# Expect clear clumps. Reviews of espresso machines do not look
# like reviews of bed sheets, and the embedding worked that out
# without ever being told what the products were.

plot_by_topic <- ggplot(plotting_data, aes(x = UMAP1, y = UMAP2, colour = topic)) +
  geom_point(size = 0.3, alpha = 0.5) +
  labs(title = "50000 reviews, coloured by product") +
  theme_minimal()

print(plot_by_topic)


# ------------------------------------------------------------
# STEP 4. Colour by rating
# ------------------------------------------------------------
#
# Expect something fainter: a gradient inside each clump, rather
# than separate clumps of its own.
#
# Look for clumps where the gradient is obvious and clumps where
# it is not. That difference is the whole question.

plot_by_rating <- ggplot(plotting_data, aes(x = UMAP1, y = UMAP2, colour = rating_observed)) +
  geom_point(size = 0.3, alpha = 0.5) +
  scale_colour_viridis_c() +
  labs(title = "The same picture, coloured by star rating") +
  theme_minimal()

print(plot_by_rating)


# ------------------------------------------------------------
# STEP 5. The same thing as a number
# ------------------------------------------------------------
#
# For each product separately, how strongly does the first
# principal component track the rating?
#
# We work through the products one at a time and store the answer.
# A loop is longer than a clever one liner, but you can see
# exactly what it does.

products <- unique(reviews$topic)

correlation_per_product <- data.frame(
  topic       = products,
  correlation = NA_real_
)

for (i in seq_along(products)) {

  this_product <- products[i]

  # Which rows belong to this product?
  rows <- which(reviews$topic == this_product)

  # Correlation between the first component and the rating,
  # using only those rows.
  correlation_per_product$correlation[i] <-
    cor(principal_components[rows, 1], reviews$rating_observed[rows])
}

# Sort so the strongest relationships come first.
correlation_per_product <- correlation_per_product[
  order(abs(correlation_per_product$correlation), decreasing = TRUE), ]

cat("How strongly the text predicts the rating, per product:\n\n")
print(head(correlation_per_product, 5), row.names = FALSE)
cat("   ...\n")
print(tail(correlation_per_product, 5), row.names = FALSE)

cat("\nThose numbers are not all the same.\n")
cat("How different they are is the question we model next.\n")
