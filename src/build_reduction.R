# =============================================================================
# src/build_reduction.R - PCA, UMAP and the modelling dataset (A3, A4)
# =============================================================================
# Turns the 50000 x 1024 embedding matrix into the things Blocks 3 and 4 load:
#   model_data.rds        labels plus 30 principal components per review
#   model_data_small.rds  a 4000 row subsample, for fitting during a session
#   umap_coords.rds       2 coordinates per review, for drawing
#
# Note we deliberately do NOT save the principal components or the labels as
# separate files. Both are already columns of model_data.rds, and keeping a
# second copy only invites the two to drift apart.
#
#   Rscript src/build_reduction.R [live_n]
# =============================================================================

source("config.R"); source("src/gen_prompts.R")
suppressPackageStartupMessages({ library(readr); library(dplyr) })

args    <- commandArgs(trailingOnly = TRUE)
live_n  <- if (length(args) >= 1) as.integer(args[1]) else 4000L
design  <- load_design()
v       <- design$design_version

d <- read_csv("data/big/reviews.csv.gz", show_col_types = FALSE)
E <- readRDS("data/big/embeddings_full.rds")
stopifnot(identical(E$text_id, d$text_id))
X <- E$emb
cat("embeddings:", nrow(X), "x", ncol(X), "\n")

# ---- PCA --------------------------------------------------------------------
# Done by eigendecomposition of the 1024x1024 covariance matrix rather than an
# SVD of the 50000x1024 data matrix. Same answer, but it turns a large, slow
# decomposition into a small, fast one - the crossproduct is the only heavy step
# and BLAS handles it well.
cat("PCA ...\n")
t0 <- Sys.time()
mu <- colMeans(X)
Xc <- sweep(X, 2, mu, "-")
C  <- crossprod(Xc) / (nrow(Xc) - 1)
ev <- eigen(C, symmetric = TRUE)
K  <- cfg$design$n_pcs
V  <- ev$vectors[, seq_len(K), drop = FALSE]
PC <- Xc %*% V
colnames(PC) <- paste0("PC", seq_len(K))
varexp <- ev$values / sum(ev$values)
cat(sprintf("  %.1f s | first %d PCs explain %.1f%% of variance\n",
            as.numeric(difftime(Sys.time(), t0, units = "secs")), K, 100 * sum(varexp[1:K])))
cat(sprintf("  PC1 %.1f%%  PC2 %.1f%%  PC3 %.1f%%\n",
            100*varexp[1], 100*varexp[2], 100*varexp[3]))

# ---- UMAP -------------------------------------------------------------------
# Run on the 30 PCs, not the raw 1024 dims: far faster and the leading PCs
# already carry the structure. Pre-computed because recomputing this during a
# webinar is minutes nobody has.
cat("UMAP ...\n")
t0 <- Sys.time()
set.seed(cfg$design$seed)
um <- uwot::umap(PC, n_neighbors = 15, min_dist = 0.1, n_threads = 4, verbose = FALSE)
colnames(um) <- c("UMAP1", "UMAP2")
cat(sprintf("  %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
saveRDS(um, "data/big/umap_coords.rds")

# ---- metadata ---------------------------------------------------------------
meta <- d |> select(text_id, topic, topic_label, expressiveness, rating,
                    replicate, persona, aspect)

# =============================================================================
# RATING FIDELITY - the design factor, after we measured that the first one
# did not work
# =============================================================================
# WHAT WE TRIED FIRST. Each topic was assigned an `expressiveness` level, on the
# theory that reviewers who only imply their verdict would produce text from
# which the rating is harder to recover - giving a text->rating relationship
# that genuinely varies by topic, which is what the hierarchical model's varying
# slopes exist to estimate.
#
# WHAT WE MEASURED. It did not work. Per-topic |cor(PC1, rating)| came out at
# 0.878-0.936 across all 25 topics - SD 0.019 - and the "understated" topics
# (0.912) scored marginally HIGHER than the "explicit" ones (0.890). The
# embedding model recovers sentiment perfectly well from understated prose; the
# style instruction changed how the text reads, not what the geometry encodes.
# Overall R^2 of a plain linear model on 30 PCs was 0.83.
#
# Two things were wrong with that dataset: the signal was implausibly strong,
# and there was nothing for tau[2] to find.
#
# WHAT WE DO INSTEAD, and why it is more realistic anyway.
# In real review data the star rating is a NOISY PROXY for the sentiment in the
# text, and how noisy depends on the product category. People give three stars
# to an excellent product because delivery was late; they give five stars to a
# mediocre one because it was cheap. Some categories are far worse for this than
# others.
#
# So we model that explicitly: with probability p_j (a property of topic j) the
# observed rating is drawn at random from the marginal instead of tracking the
# text. p_j is set from the topic's expressiveness level, so the designed factor
# is preserved - just operationalised as measurement error rather than style.
#
#   rating          = the TRUE sentiment we asked the model to write (ground truth)
#   rating_observed = what a scraper would actually see (what the model is given)
#
# This is now a proper measurement-error simulation: we know the truth, we know
# the per-topic error rate, and we can check whether the hierarchical model
# recovers the variation.
fidelity <- c(explicit = 0.05, moderate = 0.35, understated = 0.65)

set.seed(cfg$design$seed)
model_data <- meta |>
  select(text_id, topic, expressiveness, rating) |>
  mutate(topic_id = as.integer(factor(topic)),
         p_noise  = unname(fidelity[expressiveness]),
         corrupt  = runif(n()) < p_noise,
         rating_observed = ifelse(corrupt,
                                  sample(rating, n(), replace = TRUE),
                                  rating)) |>
  bind_cols(as_tibble(PC))

saveRDS(model_data, "data/big/model_data.rds")

cat("\n=== rating fidelity by design ===\n")
chk <- model_data |> group_by(topic, expressiveness) |>
  summarise(p_noise = first(p_noise),
            cor_true = abs(cor(PC1, rating)),
            cor_obs  = abs(cor(PC1, rating_observed)), .groups = "drop") |>
  group_by(expressiveness) |>
  summarise(p_noise = first(p_noise),
            mean_cor_true = round(mean(cor_true), 3),
            mean_cor_obs  = round(mean(cor_obs), 3),
            n_topics = n(), .groups = "drop")
print(chk)
sd_obs <- model_data |> group_by(topic) |>
  summarise(c = abs(cor(PC1, rating_observed)), .groups="drop")
cat("SD of per-topic correlation:", round(sd(sd_obs$c), 3),
    " (was 0.019 before - this is what tau[2] estimates)\n")

# ---- the live subsample -----------------------------------------------------
# Stratified so every topic x rating cell is represented - a hierarchical model
# with a missing group is a different model, not a smaller one.
set.seed(cfg$design$seed)
per_cell <- max(1L, round(live_n / (length(unique(model_data$topic_id)) * 5)))
live <- model_data |> group_by(topic_id, rating) |> slice_sample(n = per_cell) |> ungroup()  # stratify on TRUE rating so cells stay balanced
saveRDS(live, "data/big/model_data_small.rds")

cat("\n=== ARTIFACTS ===\n")
for (f in c("model_data.rds","model_data_small.rds","umap_coords.rds")) {
  p <- file.path("data/big", f)
  cat(sprintf("  %-24s %8.1f MB\n", f, file.size(p)/1e6))
}
cat("\nfull modelling set :", nrow(model_data), "rows,", length(unique(model_data$topic_id)), "topics\n")
cat("live subsample     :", nrow(live), "rows,", per_cell, "per topic x rating cell\n")
