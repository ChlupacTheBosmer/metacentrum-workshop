# =============================================================================
# src/build_embeddings.R - embed the full corpus (artifact A2)
# =============================================================================
# Presenter-side. Participants embed their 60 texts with the same embed()
# function; this is the same code at 800x the scale.
#
# Resumable in shards, like the generator - though it needs to be far less
# often, because embedding is dramatically faster than generation: one forward
# pass, and we batch 64 texts per request so a batch costs a single one of the
# four parallel slots.
#
#   Rscript src/build_embeddings.R
# =============================================================================

source("config.R"); source("src/api_client.R"); source("src/gen_prompts.R")
suppressPackageStartupMessages({ library(readr); library(dplyr) })

design <- load_design()
in_f  <- "data/big/reviews.csv.gz"
d <- read_csv(in_f, show_col_types = FALSE)
cat("corpus:", nrow(d), "texts\n")

out_dir <- "data/big/embedding_shards"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

chunk  <- 2000L
shards <- split(seq_len(nrow(d)), ceiling(seq_len(nrow(d)) / chunk))
cat("shards:", length(shards), "x", chunk, "\n\n")

t_start <- Sys.time()
for (s in seq_along(shards)) {
  f <- file.path(out_dir, sprintf("emb_%03d.rds", s))
  if (file.exists(f)) { cat(sprintf("[%2d/%2d] skip\n", s, length(shards))); next }
  i  <- shards[[s]]
  t0 <- Sys.time()
  E  <- embed(d$text[i], progress = FALSE)
  dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  stopifnot(nrow(E) == length(i), all(is.finite(E)))
  saveRDS(list(text_id = d$text_id[i], emb = E), f)
  cat(sprintf("[%2d/%2d] %4d texts in %5.1fs (%.0f/s)\n",
              s, length(shards), length(i), dt, length(i)/dt))
  flush.console()
}

cat("\nassembling ...\n")
parts <- lapply(list.files(out_dir, "\\.rds$", full.names = TRUE), readRDS)
ids <- unlist(lapply(parts, `[[`, "text_id"))
E   <- do.call(rbind, lapply(parts, `[[`, "emb"))
stopifnot(identical(ids, d$text_id), nrow(E) == nrow(d))

out <- "data/big/embeddings_full.rds"
saveRDS(list(text_id = ids, emb = E), out)
cat(sprintf("wrote %s : %d x %d, %.0f MB\n", out, nrow(E), ncol(E), file.size(out)/1e6))
cat(sprintf("total %.1f min\n", as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
