# ============================================================
#  05_rstudio/setup_packages.R
#  Making the R packages available
# ============================================================
#
#  THE PROBLEM
#
#  The R that MetaCentrum gives you is a plain R. It has almost no
#  packages installed. No dplyr, no ggplot2, no Stan.
#
#  You could install them yourself with install.packages(). That
#  works, but it compiles a lot of C++ and takes somewhere between
#  ten minutes and an hour, and it sometimes fails.
#
#  THE SHORTCUT
#
#  For this workshop everything has been installed already, into a
#  shared folder that everybody can read. You point R at that
#  folder and you are finished. Nothing is compiled.
#
#  Run this at the start of every R session today.
#
# ============================================================


# ------------------------------------------------------------
# STEP 1. Where the shared packages live
# ------------------------------------------------------------
#
# One folder holds the R packages. Another holds Stan, which is
# not an R package but a separate program R talks to.

shared_packages <- "/storage/plzen1/home/chlupp/workshop/Rlibs"
shared_stan     <- "/storage/plzen1/home/chlupp/workshop/cmdstan/cmdstan-2.39.0"


# ------------------------------------------------------------
# STEP 2. Tell R to look there
# ------------------------------------------------------------
#
# .libPaths() is the list of folders R searches when you call
# library(). We put our shared folder at the FRONT of that list,
# so it is looked at first, and keep everything that was already
# there behind it.

.libPaths(c(shared_packages, .libPaths()))

cat("R will now look for packages in:\n")
cat(paste0("  ", .libPaths(), collapse = "\n"), "\n\n")


# ------------------------------------------------------------
# STEP 3. Check the packages are really there
# ------------------------------------------------------------
#
# Rather than trusting it, let us load each package we need and
# print yes or no. If something says "MISSING", stop and say so
# now, instead of discovering it in an hour.
#
# requireNamespace() tries to find a package without attaching it.
# It returns TRUE or FALSE instead of stopping with an error.

needed <- c("dplyr", "ggplot2", "readr", "tidyr",
            "httr2", "jsonlite",
            "cmdstanr", "posterior", "loo", "bayesplot",
            "uwot", "future", "furrr")

cat("Checking packages:\n")

for (package_name in needed) {

  found <- requireNamespace(package_name, quietly = TRUE)

  if (found) {
    cat("  ", package_name, "  ok\n")
  } else {
    cat("  ", package_name, "  MISSING\n")
  }
}

cat("\n")


# ------------------------------------------------------------
# STEP 4. Point cmdstanr at Stan
# ------------------------------------------------------------
#
# Stan is a separate program. cmdstanr is the R package that runs
# it. It needs to be told where Stan is installed.

library(cmdstanr)

set_cmdstan_path(shared_stan)

cat("Stan version:", cmdstan_version(), "\n\n")
cat("Setup finished. You can start working.\n")


# ============================================================
#  IF YOU WANT TO DO THIS PROPERLY IN YOUR OWN PROJECT
#
#  A shared folder someone else maintains is fine for a workshop.
#  For your own work you have two better options:
#
#    1. install the packages into your own library once, and add
#       the .libPaths() line to your script
#
#    2. build a container that holds R and every package at fixed
#       versions. That is section 12.
#
#  DOCUMENTATION
#      https://docs.metacentrum.cz/en/docs/software/modules
#      https://docs.metacentrum.cz/en/docs/software/install-software
# ============================================================
