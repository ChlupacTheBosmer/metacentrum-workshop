# ============================================================
#  11_job_arrays/merge_results.R
#  Putting 30 machines back together
# ============================================================
#
#  Each of the 30 jobs wrote one small file. This reads them all
#  and makes a single table.
#
#      Rscript 11_job_arrays/merge_results.R signal
#      Rscript 11_job_arrays/merge_results.R control
#
#  IT DOES NOT MIND MISSING FILES
#
#  Run it five minutes after submitting and some jobs will still
#  be queued. It says so and merges what exists. Run it again
#  later for the rest.
#
#  That is deliberate. Waiting for a cluster is normal, and an
#  error message would teach the wrong thing.
#
# ============================================================

source("config.R")

library(dplyr)
library(ggplot2)


# ------------------------------------------------------------
# STEP 1. Which arm are we merging?
# ------------------------------------------------------------

arguments <- commandArgs(trailingOnly = TRUE)

if (length(arguments) >= 1) {
  which_arm <- arguments[1]
} else {
  which_arm <- "signal"
}

cat("Merging arm:", which_arm, "\n\n")


# ------------------------------------------------------------
# STEP 2. Find the files
# ------------------------------------------------------------

results_folder <- file.path(cfg$storage$results_dir, which_arm)

# list.files with a pattern finds only the files we wrote, and
# ignores anything else that happens to be in the folder.
result_files <- list.files(
  path       = results_folder,
  pattern    = "^rep_[0-9]+\\.rds$",
  full.names = TRUE
)

if (length(result_files) == 0) {
  stop("No results in ", results_folder, "\n",
       "  Have the jobs started? Check with: qstat -t -u $USER")
}


# ------------------------------------------------------------
# STEP 3. Read them all
# ------------------------------------------------------------
#
# We read them one at a time into a list, then stack the list
# into one table. Doing it in two steps is easier to follow than
# doing it in one.

all_pieces <- list()

for (i in seq_along(result_files)) {
  all_pieces[[i]] <- readRDS(result_files[i])
}

everything <- bind_rows(all_pieces)


# ------------------------------------------------------------
# STEP 4. Say what arrived and what did not
# ------------------------------------------------------------

expected_total <- cfg$pbs$n_replicates

arrived <- sort(unique(everything$replicate))
missing <- setdiff(1:expected_total, arrived)

cat("Merged", length(arrived), "of", expected_total, "repeats.\n")

if (length(missing) > 0) {
  cat("Still waiting on:", paste(missing, collapse = ", "), "\n")
  cat("Run this again in a few minutes.\n")
}

cat("\n")


# ------------------------------------------------------------
# STEP 5. Did any of them go wrong?
# ------------------------------------------------------------
#
# Two warning signs, same as for a single fit:
#   divergences above 0
#   rhat above 1.01
#
# With 30 independent fits, expect the occasional bad one. That
# is useful information, not a problem. A single fit would never
# show it.

one_row_per_fit <- everything[!duplicated(everything$replicate), ]

n_clean <- sum(one_row_per_fit$divergences == 0)

cat("Fits with no divergences:", n_clean, "of", nrow(one_row_per_fit), "\n")
cat("Largest rhat seen:", round(max(everything$rhat, na.rm = TRUE), 4), "\n")
cat("Median run time:", round(median(one_row_per_fit$elapsed_min), 2), "minutes\n\n")


# ------------------------------------------------------------
# STEP 6. Save the table
# ------------------------------------------------------------

output_file <- file.path(
  cfg$storage$results_dir,
  paste0("summary_", which_arm, ".csv")
)

write.csv(everything, output_file, row.names = FALSE)

cat("Wrote", output_file, "\n")


# ------------------------------------------------------------
# STEP 7. Draw the spread
# ------------------------------------------------------------
#
# One row per repeat, showing the estimate and its range. If the
# repeats agree, the answer is stable. If they scatter widely,
# it is not.

interesting <- everything %>%
  filter(variable %in% c("beta[1]", "tau[2]"))

the_plot <- ggplot(interesting,
                   aes(x = mean, y = factor(replicate))) +
  geom_point() +
  # A horizontal range bar. In current ggplot2 this is geom_errorbar with
  # orientation = "y"; the old geom_errorbarh is deprecated and warns.
  geom_errorbar(aes(xmin = q05, xmax = q95), orientation = "y", width = 0) +
  facet_wrap(~ variable, scales = "free_x") +
  labs(
    title = paste("Across", length(arrived), "repeats,", which_arm, "arm"),
    x     = "estimate, with 90 percent range",
    y     = "repeat"
  ) +
  theme_minimal()

plot_file <- file.path(
  cfg$storage$results_dir,
  paste0("repeats_", which_arm, ".png")
)

ggsave(plot_file, the_plot, width = 9, height = 6, dpi = 120)

cat("Wrote", plot_file, "\n")
