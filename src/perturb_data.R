# =============================================================================
# src/perturb_data.R - make one perturbed replicate of the modelling dataset
# =============================================================================
# The workshop's Level-2 parallelism story needs 30 jobs that are the same shape
# but not the same work. Each replicate refits the model to a resampled version
# of the data, which is a bootstrap: it tells us how much our conclusions would
# wobble if we had collected a slightly different corpus.
#
# The resample is STRATIFIED BY TOPIC, and by topic ONLY. Two reasons, and the
# second one cost us a wrong answer before we caught it:
#
#   1. An unstratified bootstrap could, by chance, drop a whole topic - and a
#      hierarchical model with a missing group is a different model, not a
#      noisier one.
#
#   2. We must NOT also stratify on the outcome. Our first version stratified on
#      (topic, rating_observed), which forces every topic to show the same
#      balanced distribution of ratings. That is conditioning on the outcome,
#      and it destroys precisely the between-topic variation the model exists to
#      measure: tau[2] came out at 0.049 in a replicate against 0.260 on the
#      same data fitted directly. Stratify on the grouping factor; never on the
#      thing you are trying to explain.
# =============================================================================

#' @param df   the full modelling dataset
#' @param seed integer; same seed -> same replicate, on any machine
#' @param arm  "signal" (the real design) or "control" (labels permuted within
#'             topic, breaking the text->rating link while keeping everything
#'             else identical). The control arm is how we show the model
#'             correctly finding NOTHING when there is nothing to find.
#' @param frac fraction of each stratum to draw (with replacement)
#' @param n_target if given, overrides `frac` so the result has roughly this
#'   many rows. Each replicate is then a bootstrap draw of the SAME SIZE as the
#'   fit done live in Block 4, which is what makes the two directly comparable -
#'   and it keeps a 2-CPU job comfortably inside its walltime.
perturb_data <- function(df, seed, arm = c("signal", "control"), frac = 1.0,
                         n_target = NULL) {
  arm <- match.arg(arm)
  set.seed(seed)

  if (!is.null(n_target)) frac <- n_target / nrow(df)

  idx <- unlist(lapply(
    split(seq_len(nrow(df)), df$topic_id, drop = TRUE),
    function(ii) sample(ii, size = max(2L, round(length(ii) * frac)), replace = TRUE)
  ), use.names = FALSE)

  out <- df[idx, , drop = FALSE]

  if (arm == "control") {
    # Permute the outcome WITHIN topic. This destroys any relationship between
    # the text (hence its PCs) and the rating, while preserving the marginal
    # distribution of ratings and the topic structure exactly. It is the
    # canonical permutation null: if the model still reports a strong effect
    # here, the effect was an artefact of the method, not the data.
    out <- do.call(rbind, lapply(split(out, out$topic_id), function(g) {
      g$rating_observed <- sample(g$rating_observed)
      g
    }))
  }

  rownames(out) <- NULL
  out
}
