# ============================================================
#  11_job_arrays/fit_one_replicate.R
#  The work that ONE job in the array does
# ============================================================
#
#  THE SITUATION
#
#  We want to repeat the same analysis 30 times, each time on a
#  slightly different version of the data, to see how much the
#  answer moves around.
#
#  Thirty jobs will run this file. They are all identical except
#  for one number: which repeat they are. This file's only clever
#  part is working out that number and using it.
#
#  You can also run it by hand to test:
#
#      Rscript 11_job_arrays/fit_one_replicate.R 7
#
# ============================================================

source("config.R")
source("src/fit_model.R")
source("src/perturb_data.R")


# ------------------------------------------------------------
# STEP 1. Which repeat am I?
# ------------------------------------------------------------
#
# Two ways this number can arrive.
#
#   a) you typed it after the filename, for testing
#   b) the scheduler put it in an environment variable, which is
#      what happens when the array runs
#
# We look for (a) first, then fall back to (b).

arguments <- commandArgs(trailingOnly = TRUE)

if (length(arguments) >= 1) {

  # Case (a): the number was typed on the command line.
  my_number <- as.integer(arguments[1])

} else {

  # Case (b): PBS sets an environment variable for each job in the
  # array. The first job sees 1, the second sees 2, and so on.
  from_pbs <- Sys.getenv("PBS_ARRAY_INDEX")

  if (from_pbs == "") {
    stop("I do not know which repeat I am. Either pass a number, ",
         "or run me inside a job array.")
  }

  my_number <- as.integer(from_pbs)
}

cat("I am repeat number", my_number, "\n")
cat("Running on machine:", Sys.info()[["nodename"]], "\n\n")


# ------------------------------------------------------------
# STEP 2. Which version of the study?
# ------------------------------------------------------------
#
# "signal"  the real data
# "control" the same data with the ratings shuffled, so there is
#           nothing to find. A check that our method does not
#           invent results.

which_arm <- Sys.getenv("WS_ARM", unset = "signal")

cat("Arm:", which_arm, "\n\n")


# ------------------------------------------------------------
# STEP 3. Make this repeat's version of the data
# ------------------------------------------------------------
#
# Every repeat draws a different sample. The seed is built from
# my_number, so repeat 7 always produces exactly the same sample,
# on any machine, on any day.

artifacts <- cfg$storage$artifacts_dir
full_data <- readRDS(file.path(artifacts, "model_data.rds"))
live_data <- readRDS(file.path(artifacts, "model_data_small.rds"))

my_seed <- cfg$design$seed + my_number

my_data <- perturb_data(
  df       = full_data,
  seed     = my_seed,
  arm      = which_arm,
  n_target = nrow(live_data)
)

cat("My sample has", nrow(my_data), "rows.\n\n")


# ------------------------------------------------------------
# STEP 4. Fit
# ------------------------------------------------------------

cat("Fitting.\n")

time_before <- Sys.time()

fit <- fit_model(
  dat           = prepare_stan_data(my_data),
  cores         = cfg$pbs$rep_ncpus,
  chains        = cfg$model$rep_chains,
  iter_warmup   = cfg$model$rep_iter_warmup,
  iter_sampling = cfg$model$rep_iter_sampling,
  model_file    = "09_model/model.stan",
  seed          = my_seed
)

time_after <- Sys.time()
minutes_taken <- as.numeric(difftime(time_after, time_before, units = "mins"))


# ------------------------------------------------------------
# STEP 5. Save a SMALL answer
# ------------------------------------------------------------
#
# We deliberately do not save the whole fitted model. Thirty of
# those would be tens of gigabytes and very slow to combine.
#
# We keep only the summary numbers we actually look at. Each file
# is under a kilobyte.

output_folder <- file.path(cfg$storage$results_dir, which_arm)
dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)

my_summary <- summarise_fit(fit, replicate = my_number, arm = which_arm)
my_summary$elapsed_min <- minutes_taken

output_file <- file.path(output_folder, sprintf("rep_%03d.rds", my_number))
saveRDS(my_summary, output_file)

cat("\n")
cat("Took", round(minutes_taken, 1), "minutes.\n")
cat("Divergences:", my_summary$divergences[1], "\n")
cat("Wrote:", output_file, "\n")
