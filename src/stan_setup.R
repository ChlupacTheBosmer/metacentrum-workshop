# ============================================================
#  src/stan_setup.R
#  Making sure R can find Stan, wherever it is running
# ============================================================
#
#  THE PROBLEM THIS SOLVES
#
#  Stan is not an R package. It is a separate program, and the R
#  package cmdstanr has to be told where it lives.
#
#  In an RStudio session you run 05_rstudio/setup_packages.R once
#  and it is set for the rest of that session. But scripts also
#  get run on their own:
#
#      Rscript 09_model/fit_once.R
#
#  and inside jobs, where nobody ran setup_packages.R first. In
#  those cases cmdstanr does not know where Stan is and stops
#  with "CmdStan path has not been set yet", which is not a very
#  helpful thing to read.
#
#  So instead of relying on somebody remembering, we look for
#  Stan in the places it can be, and set it ourselves.
#
# ============================================================


#' Point cmdstanr at Stan, if it is not already pointed at it.
#'
#' Safe to call as many times as you like. If the path is already
#' set it does nothing.
ensure_stan_is_found <- function() {

  if (!requireNamespace("cmdstanr", quietly = TRUE)) {
    stop("The package cmdstanr is not available.\n",
         "  R is looking for packages in:\n",
         paste0("      ", .libPaths(), collapse = "\n"), "\n\n",
         "  The shared folder should be one of those. Run this and try again:\n",
         "      source(\"config.R\")\n",
         call. = FALSE)
  }

  suppressPackageStartupMessages(library(cmdstanr))

  # Is it already set? cmdstan_path() throws an error when it is
  # not, so we catch that rather than let it stop the script.
  already_set <- tryCatch({
    cmdstanr::cmdstan_path()
    TRUE
  }, error = function(e) FALSE)

  if (already_set) {
    return(invisible(cmdstanr::cmdstan_path()))
  }

  # Not set. Look in the two places it can be.
  #
  #   1. Inside the workshop container, Stan was built into the
  #      image itself.
  #   2. On a normal RStudio session, it is in the shared folder
  #      on plzen1 that everybody reads.
  #
  # We check the container first, because if we are inside one
  # that copy is the right one to use.
  possible_places <- c(
    "/opt/cmdstan/cmdstan",
    cfg$modules$shared_cmdstan
  )

  for (place in possible_places) {

    if (dir.exists(place)) {
      cmdstanr::set_cmdstan_path(place)
      return(invisible(place))
    }
  }

  # Nowhere. Say so clearly, and say what to do.
  stop(
    "Cannot find Stan. Looked in:\n",
    paste0("    ", possible_places, collapse = "\n"), "\n\n",
    "  If you are in RStudio, run this first:\n",
    "      source(\"05_rstudio/setup_packages.R\")\n",
    call. = FALSE
  )
}
