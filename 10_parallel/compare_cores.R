# ============================================================
#  10_parallel/compare_cores.R
#  One machine, more cores
# ============================================================
#
#  THE IDEA
#
#  The model is fitted by four chains. A chain is a separate
#  exploration that starts from a different place. They never
#  talk to each other while running. We only compare them at the
#  end.
#
#  Because they never talk, they can run at the same time. Four
#  chains on four cores instead of four chains one after another.
#
#  This is the easy kind of parallel work. One machine, one extra
#  argument, no change to the statistics.
#
#  We run it both ways and time it.
#
# ============================================================

source("config.R")
source("src/fit_model.R")


artifacts  <- cfg$storage$artifacts_dir
model_data <- readRDS(file.path(artifacts, "model_data_small.rds"))
stan_data  <- prepare_stan_data(model_data)


# ------------------------------------------------------------
# RUN 1. Four chains, one core
# ------------------------------------------------------------
#
# The chains take turns. One finishes, the next starts.

cat("============================================\n")
cat("Run 1: four chains, ONE core\n")
cat("============================================\n\n")

time_before <- Sys.time()

fit_one_core <- fit_model(
  dat        = stan_data,
  cores      = 1,
  chains     = 4,
  model_file = "09_model/model.stan"
)

time_after <- Sys.time()
seconds_one_core <- as.numeric(difftime(time_after, time_before, units = "secs"))

cat("\nTook", round(seconds_one_core, 1), "seconds.\n\n")


# ------------------------------------------------------------
# RUN 2. The same four chains, four cores
# ------------------------------------------------------------
#
# One argument is different. Everything else is identical.

cat("============================================\n")
cat("Run 2: four chains, FOUR cores\n")
cat("============================================\n\n")

time_before <- Sys.time()

fit_four_cores <- fit_model(
  dat        = stan_data,
  cores      = 4,
  chains     = 4,
  model_file = "09_model/model.stan"
)

time_after <- Sys.time()
seconds_four_cores <- as.numeric(difftime(time_after, time_before, units = "secs"))

cat("\nTook", round(seconds_four_cores, 1), "seconds.\n\n")


# ------------------------------------------------------------
# The comparison
# ------------------------------------------------------------

speed_up <- seconds_one_core / seconds_four_cores

cat("============================================\n")
cat("Result\n")
cat("============================================\n\n")
cat("  one core :", round(seconds_one_core, 1), "seconds\n")
cat("  four cores:", round(seconds_four_cores, 1), "seconds\n")
cat("  speed up  :", round(speed_up, 2), "times\n\n")


# ------------------------------------------------------------
# Why it is not four times faster
# ------------------------------------------------------------

cat("Three reasons it is less than 4x:\n\n")
cat("  1. you wait for the slowest chain, not the average one\n")
cat("  2. the warm up phase takes different lengths in each chain\n")
cat("  3. starting and collecting the chains costs a little\n\n")

cat("And an important limit:\n\n")
cat("  there are only four chains, so only four pieces of work.\n")
cat("  Asking for 40 cores would change nothing at all.\n\n")

cat("To go faster than this you need more MACHINES.\n")
cat("That is section 11.\n")
