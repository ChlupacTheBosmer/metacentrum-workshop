# ============================================================
#  09_model/fit_once.R
#  Fitting the model once
# ============================================================
#
#  THE QUESTION
#
#  Does the text of a review tell us its star rating, and does
#  that differ from one product to another?
#
#  THE MODEL, in words
#
#  For each review we build a single number from its principal
#  components. That number decides which star rating is likely.
#
#      score = (the average effect of each component)
#            + (this product's own adjustment)
#            + (this product's own extra sensitivity)
#
#  The last line is the interesting one. It lets the relationship
#  be stronger for some products than others, and it lets the
#  model estimate how much stronger.
#
#  The file 09_model/model.stan contains the model itself, with a
#  comment on every line.
#
# ============================================================

source("config.R")
source("src/fit_model.R")

library(dplyr)


# ------------------------------------------------------------
# STEP 1. Load the data
# ------------------------------------------------------------
#
# We use a smaller slice of the 50000, not all of it. 4000 rows
# is enough to answer the question and small enough to fit while
# you watch.

artifacts <- cfg$storage$artifacts_dir

model_data <- readRDS(file.path(artifacts, "model_data_small.rds"))

cat("Rows:    ", nrow(model_data), "\n")
cat("Products:", length(unique(model_data$topic_id)), "\n\n")


# ------------------------------------------------------------
# STEP 2. Put it in the shape Stan expects
# ------------------------------------------------------------
#
# Stan wants a plain list of numbers and matrices, not a data
# frame. prepare_stan_data() does that conversion and also
# standardises the components, because the model assumes they
# are on a standard scale.

stan_data <- prepare_stan_data(model_data)


# ------------------------------------------------------------
# STEP 3. Fit
# ------------------------------------------------------------
#
# The model is fitted by running four independent chains. A chain
# is one exploration of the possible answers. Running four and
# comparing them is how we check the answer settled down.
#
# parallel_chains = 4 runs them at the same time on four cores.
# Section 10 is about exactly that number.

cat("Fitting. This takes about half a minute.\n\n")

fit <- fit_model(
  dat             = stan_data,
  cores           = 4,
  chains          = 4,
  model_file      = "09_model/model.stan"
)


# ------------------------------------------------------------
# STEP 4. Did it work?
# ------------------------------------------------------------
#
# Two checks come before any result. If either fails, the numbers
# below mean nothing.
#
#   divergences: places where the sampler got stuck. Should be 0.
#   rhat: whether the four chains agree. Should be under 1.01.

diagnostics <- fit$sampler_diagnostics()
n_divergences <- sum(diagnostics[, , "divergent__"])

summary_table <- fit$summary(c("beta[1]", "beta[2]", "tau[1]", "tau[2]"))

cat("Divergences:", n_divergences, " (want 0)\n")
cat("Largest rhat:", round(max(summary_table$rhat), 4), " (want under 1.01)\n\n")


# ------------------------------------------------------------
# STEP 5. The answer
# ------------------------------------------------------------

print(summary_table)

cat("\n")
cat("beta[1] is the average effect of the first component on the\n")
cat("rating, across all products.\n\n")
cat("tau[2] is the one to look at. It is how much that effect\n")
cat("VARIES between products.\n\n")
cat("If tau[2] sits clearly above zero, then products genuinely\n")
cat("differ, and a single average would have hidden that.\n")
