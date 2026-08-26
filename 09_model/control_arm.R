# ============================================================
#  09_model/control_arm.R
#  Checking that the method does not invent results
# ============================================================
#
#  THE OBJECTION
#
#  We told a language model which rating to write for. So of
#  course the rating can be recovered from the text. Somebody in
#  the room should be suspicious of that, and they would be right.
#
#  How do we know the model is finding something real, rather
#  than any method finding something in any data?
#
#  THE ANSWER
#
#  Break the link and fit again.
#
#  We keep the same texts, the same components, the same
#  products. We only shuffle the ratings around within each
#  product, so that no review's text matches its own rating any
#  more.
#
#  Everything else stays identical. The number of each rating
#  stays identical. The only thing destroyed is the connection
#  between the text and the label.
#
#  A correct method must now find NOTHING.
#
#  If it still reports a strong result, then the result was
#  never about the data.
#
#  This is called a permutation null, and it costs one extra fit.
#
# ============================================================

source("config.R")
source("src/fit_model.R")
source("src/perturb_data.R")

library(dplyr)


artifacts  <- cfg$storage$artifacts_dir
model_data <- readRDS(file.path(artifacts, "model_data_small.rds"))


# ------------------------------------------------------------
# FIT 1. The real data
# ------------------------------------------------------------

cat("============================================\n")
cat("Fit 1: the real data\n")
cat("============================================\n\n")

# We fit the data exactly as it is. No resampling.
#
# The only thing that should differ between the two fits below is whether
# the ratings match their reviews. Resampling first would add a second
# difference and make the comparison less clean.

fit_real <- fit_model(
  dat        = prepare_stan_data(model_data),
  cores      = 4,
  chains     = 4,
  model_file = "09_model/model.stan"
)


# ------------------------------------------------------------
# FIT 2. The same data with the ratings shuffled
# ------------------------------------------------------------
#
# perturb_data() with arm = "control" does the shuffling. It
# works product by product, so each product keeps its own mix of
# ratings. Only the pairing is broken.

cat("\n============================================\n")
cat("Fit 2: ratings shuffled within each product\n")
cat("============================================\n\n")

# arm = "control" shuffles the ratings within each product. frac = 1 and no
# n_target means every row is kept, so the only change is the shuffling.
shuffled_data <- perturb_data(
  df   = model_data,
  seed = cfg$design$seed,
  arm  = "control"
)

fit_shuffled <- fit_model(
  dat        = prepare_stan_data(shuffled_data),
  cores      = 4,
  chains     = 4,
  model_file = "09_model/model.stan"
)


# ------------------------------------------------------------
# Compare
# ------------------------------------------------------------
#
# Two numbers are enough.
#
#   beta[1]  the average effect of the first component
#   tau[2]   how much that effect varies between products

which_numbers <- c("beta[1]", "tau[2]")

summary_real <- fit_real$summary(which_numbers)
summary_real$data <- "real"

summary_shuffled <- fit_shuffled$summary(which_numbers)
summary_shuffled$data <- "shuffled"

comparison <- bind_rows(summary_real, summary_shuffled)
comparison <- comparison[, c("data", "variable", "mean", "q5", "q95", "rhat")]

cat("\n============================================\n")
cat("Side by side\n")
cat("============================================\n\n")

print(as.data.frame(comparison), digits = 3, row.names = FALSE)


# ------------------------------------------------------------
# What to look for
# ------------------------------------------------------------

cat("\n")
cat("A note on how much these numbers move:\n")
cat("  tau[2] is estimated from only 25 products, so it is not pinned\n")
cat("  down tightly. Its interval is wide and the middle of it moves\n")
cat("  between samples. Read the interval, not the single number.\n\n")
cat("On the real data:\n")
cat("  beta[1] should be clearly away from zero\n")
cat("  tau[2]  should be clearly above zero\n\n")
cat("On the shuffled data:\n")
cat("  beta[1] should sit across zero\n")
cat("  tau[2]  should collapse towards zero\n\n")
cat("If the shuffled data shows an effect, do not believe the\n")
cat("real one either.\n")
