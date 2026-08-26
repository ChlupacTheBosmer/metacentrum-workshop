# Build the workshop's shared R library, INSIDE the same image that the
# OnDemand RStudio app runs, so the compiled objects are binary-compatible
# with participants' interactive sessions.
lib <- "/storage/plzen1/home/chlupp/workshop/Rlibs"
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
repos <- c(stan = "https://stan-dev.r-universe.dev", CRAN = "https://cloud.r-project.org")

cat("R:", R.version.string, "\nlib:", lib, "\n\n")
for (p in c("posterior", "loo", "bayesplot", "future", "furrr", "uwot", "cmdstanr")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    cat("installing", p, "...\n"); flush.console()
    try(install.packages(p, lib = lib, repos = repos, Ncpus = 4))
  }
  cat(sprintf("  %-10s %s\n", p,
      ifelse(requireNamespace(p, quietly = TRUE), "ok", "FAILED")))
}
