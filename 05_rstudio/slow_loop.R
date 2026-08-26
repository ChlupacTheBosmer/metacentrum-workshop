# ============================================================
#  05_rstudio/slow_loop.R
#  Something slow, to have a number to compare against
# ============================================================
#
#  This does a small bootstrap. We take a sample of numbers,
#  draw from it with replacement many times, and record the
#  median each time. That gives us a sense of how much the
#  median would move around if we collected the data again.
#
#  The statistics do not matter here. What matters is that it
#  takes real time, and that every repetition is independent of
#  every other one.
#
#  Run it and write the time down.
#
# ============================================================


# Fix the random numbers so everybody gets the same result.
set.seed(1)

# How many times to repeat the whole thing.
n_repeats <- 2000

# Our pretend dataset: 5000 numbers.
data_values <- rnorm(5000)


# ------------------------------------------------------------
# Somewhere to put the answers
# ------------------------------------------------------------
#
# We make an empty vector of the right length up front and fill
# it in. That is much faster than growing a vector as you go,
# because R does not have to copy it every time.

results <- numeric(n_repeats)


# ------------------------------------------------------------
# The loop
# ------------------------------------------------------------

cat("Running", n_repeats, "repetitions, one after another.\n")

# Sys.time() records the clock now. We take it before and after
# and subtract, which tells us how long the work took.
time_started <- Sys.time()

for (i in 1:n_repeats) {

  # Draw a new sample of the same size, with replacement.
  # "with replacement" means the same value can be picked twice.
  positions <- sample(length(data_values), replace = TRUE)
  resampled <- data_values[positions]

  # Record the median of this particular resample.
  results[i] <- median(resampled)
}

time_finished <- Sys.time()

seconds_taken <- as.numeric(difftime(time_finished, time_started, units = "secs"))


# ------------------------------------------------------------
# Report
# ------------------------------------------------------------

cat("\n")
cat("Finished in", round(seconds_taken, 1), "seconds.\n")
cat("The median moved around by about", round(sd(results), 4), "\n")
cat("\n")
cat("Write that time down.\n")
cat("\n")
cat("Now think about this:\n")
cat("did any repetition need the answer from any other one?\n")
