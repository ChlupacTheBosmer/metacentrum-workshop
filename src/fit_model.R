# =============================================================================
# src/fit_model.R - fit the hierarchical ordinal model once (handover F6/F10)
# =============================================================================
# One function, used by three different callers:
#   * Block 4, interactively, to compare cores = 1 against cores = N;
#   * Block 5, inside a PBS array job, once per perturbed replicate;
#   * the artifact build, to produce the fallback fits that ship in the repo.
#
# Keeping all three on one code path is deliberate. If the PBS jobs and the
# in-session fit could drift apart, the Block 5 comparison would be comparing
# two different models and nobody would notice.
# =============================================================================

suppressPackageStartupMessages({ library(cmdstanr); library(posterior) })

#' Fit the model to a prepared modelling dataset.
#'
#' @param dat    list with N, J, K, P, C, topic, y, x  (see prepare_stan_data)
#' @param cores  how many chains to run in parallel. THE point of Block 4.
#' @param chains number of chains
#' @param model_file path to the .stan file (default 09_model/model.stan)
#' @return a CmdStanMCMC object
fit_model <- function(dat,
                      cores = 1L,
                      chains = 4L,
                      iter_warmup = 1000L,
                      iter_sampling = 1000L,
                      model_file = "09_model/model.stan",
                      exe_file = NULL,
                      seed = 20260823L,
                      refresh = 0L) {

  # ---- use the pre-compiled executable if we have one ---------------------
  # Compiling this model takes SEVERAL MINUTES - Stan Math's headers are huge
  # and it is genuinely CPU-bound (measured on a MetaCentrum frontend). Five
  # participants each burning five minutes on an identical compile is twenty-five
  # minutes of a workshop spent watching g++.
  #
  # So we compile ONCE and ship the binary. cmdstanr will reuse an exe passed via
  # `exe_file` as long as it is newer than the .stan source, and skip compiling
  # entirely. If the binary is missing or stale it falls back to compiling, so
  # this is an optimisation and never a dependency.
  if (is.null(exe_file)) {
    shared <- file.path(cfg$storage$artifacts_dir, "model_binary")
    if (file.exists(shared)) exe_file <- shared
  }

  mod <- if (!is.null(exe_file) && file.exists(exe_file)) {
    message("using pre-compiled model: ", exe_file)
    cmdstan_model(model_file, exe_file = exe_file, compile = FALSE)
  } else {
    message("no pre-compiled binary found - compiling (this takes a few minutes)")
    cmdstan_model(model_file)
  }

  # ---- explicit initial values ------------------------------------------
  # Stan's default is to draw inits uniformly on (-2, 2) on the unconstrained
  # scale. For an `ordered` vector that occasionally produces cutpoints that
  # are numerically tied, and for a Cholesky correlation factor it can produce
  # a zero on the diagonal. Neither is fatal - the sampler rejects the proposal
  # and moves on - but each prints an alarming red "Exception:" block during
  # warmup, and a room full of statisticians watching their first Stan run
  # should not have to be told to ignore red text.
  #
  # Starting from sensible values removes the noise entirely: cutpoints spread
  # across the logit scale, small non-zero scales, slopes at zero.
  init_fun <- function() list(
    beta    = rep(0, dat$K),
    c       = seq(-2, 2, length.out = dat$C - 1),
    tau     = rep(0.5, dat$P + 1),
    z_u     = matrix(0, dat$P + 1, dat$J),
    L_Omega = diag(dat$P + 1)
  )

  mod$sample(
    data            = dat,
    chains          = chains,
    parallel_chains = cores,      # <- the one line Block 4 is about
    iter_warmup     = iter_warmup,
    iter_sampling   = iter_sampling,
    seed            = seed,
    init            = init_fun,
    refresh         = refresh,
    show_messages   = FALSE,
    # Stan prints "Metropolis proposal is about to be rejected" during warmup
    # when a proposal lands on tied cutpoints or a degenerate Cholesky factor.
    # Stan's own message says sporadic occurrences are fine, and our diagnostics
    # confirm it: 0 divergences, R-hat 1.005. But a wall of red "Exception:"
    # text in front of people seeing their first Stan run is actively harmful -
    # they will remember the scary output, not the result.
    # We suppress it and TELL them we did, rather than pretend it never happens.
    show_exceptions = FALSE
  )
}

#' Turn a modelling tibble into the list Stan expects.
#'
#' Standardises the PC columns, because the priors in model.stan are written
#' for standardised predictors. Doing it here rather than asking the user to
#' remember means the prior can never quietly stop matching the data.
prepare_stan_data <- function(df, n_pcs = 30L, n_varying = 3L, n_cat = 5L,
                              outcome = "rating_observed") {
  pc_cols <- paste0("PC", seq_len(n_pcs))
  stopifnot(all(pc_cols %in% names(df)))

  # We model `rating_observed` - the noisy star rating a scraper would actually
  # see - NOT `rating`, the true sentiment we asked the LLM to write. The gap
  # between them is the measurement error whose size varies by topic, and
  # recovering that variation is the point of the exercise. Using the true
  # rating would be cheating: it is not observable in any real dataset.
  if (!outcome %in% names(df))
    stop("outcome column '", outcome, "' not found. Did you rebuild artifacts?",
         call. = FALSE)

  x <- scale(as.matrix(df[, pc_cols]))
  attr(x, "scaled:center") <- attr(x, "scaled:scale") <- NULL

  list(
    N     = nrow(df),
    J     = length(unique(df$topic_id)),
    K     = n_pcs,
    P     = n_varying,
    C     = n_cat,
    topic = as.integer(df$topic_id),
    y     = as.integer(df[[outcome]]),
    x     = x
  )
}

#' Extract the small summary that is worth keeping from a fit.
#'
#' A full CmdStanMCMC object is hundreds of MB. Thirty of those would be a
#' storage problem and a merge problem. We keep only the parameters the
#' workshop interprets, which makes each replicate result a few kB.
summarise_fit <- function(fit, replicate = NA_integer_, arm = NA_character_) {
  vars <- c("beta[1]", "beta[2]", "beta[3]",
            "tau[1]", "tau[2]", "tau[3]", "tau[4]",
            "tau_slope_pc1")
  # NOTE: cmdstanr names quantile columns from the quantile itself ("5%", "95%"),
  # ignoring the argument name you give it. Rename explicitly so downstream code
  # can rely on syntactic names.
  s <- fit$summary(vars, mean = mean, sd = sd,
                   q05 = ~quantile(.x, 0.05), q95 = ~quantile(.x, 0.95),
                   rhat = posterior::rhat, ess_bulk = posterior::ess_bulk)
  names(s)[names(s) == "5%"]  <- "q05"
  names(s)[names(s) == "95%"] <- "q95"
  s$replicate <- replicate
  s$arm       <- arm
  d <- fit$sampler_diagnostics()
  s$divergences <- sum(d[, , "divergent__"])
  s
}
