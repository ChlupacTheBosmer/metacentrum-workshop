# =============================================================================
# src/generate_corpus.R - build the full pre-generated corpus (artifact A1)
# =============================================================================
# This is the PRESENTER-side script. Participants never run it; they run the
# 60-text slice in 07_ai_services/generate_texts.R. But it is the same code path
# (same prompt factory, same API client), which is the point: the big artifact
# is produced by the repo's own machinery, so if the artifact is good then the
# participant path is good too.
#
# Resumable by design. It writes one gzipped CSV shard per chunk, and re-running
# skips shards that already exist - so an interrupted overnight run costs you
# only the chunk that was in flight.
#
# Usage:  Rscript src/generate_corpus.R [n_replicates_per_cell] [chunk_size]
#         (run from the repo root)
# =============================================================================

source("config.R"); source("src/api_client.R"); source("src/gen_prompts.R")
suppressPackageStartupMessages({ library(readr); library(dplyr) })

args   <- commandArgs(trailingOnly = TRUE)
design <- load_design()
n_rep  <- if (length(args) >= 1) as.integer(args[1]) else design$full_corpus$n_replicates_per_cell
chunk  <- if (length(args) >= 2) as.integer(args[2]) else 500L

# Shard dir is keyed to the run size, so a small rehearsal run and the real
# 50k run can never share (and corrupt) each other's shards.
# Where the part-finished pieces go. Re-running skips pieces that already
# exist, which is what makes an interrupted overnight run cheap to resume.
#
# IMPORTANT: if you change anything in design/design.json, delete this
# directory first. Otherwise the old pieces are kept and you end up with a
# corpus made by two different designs.
dver    <- design$design_version %||% 1
out_dir <- "data/big/corpus_shards"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

prompts <- make_prompts(n_replicates = n_rep, design = design)
set.seed(cfg$design$seed)
prompts <- prompts[sample(nrow(prompts)), ]   # interleave topics, so that a
                                              # partial run is still balanced
n <- nrow(prompts)
shards <- split(seq_len(n), ceiling(seq_len(n) / chunk))

cat(sprintf("Corpus generation\n  texts      : %d\n  model      : %s\n  concurrency: %d\n  shards     : %d x %d\n\n",
            n, cfg$ai$chat_model, cfg$ai$chat_concurrency, length(shards), chunk))
flush.console()

t_start <- Sys.time()
for (s in seq_along(shards)) {
  f <- file.path(out_dir, sprintf("shard_%04d.csv.gz", s))
  if (file.exists(f)) { cat(sprintf("[%3d/%3d] skip (exists)\n", s, length(shards))); flush.console(); next }

  p  <- prompts[shards[[s]], ]
  t0 <- Sys.time()
  txt <- chat_many(p$user_prompt, system = p$system_prompt[1],
                   temperature = design$generation$temperature,
                   max_tokens  = design$generation$max_tokens,
                   seed        = p$seed,     # decorrelates repeated prompts
                   progress = FALSE)
  dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

  res <- p |>
    mutate(text = txt,
           model = cfg$ai$chat_model,
           temperature = design$generation$temperature,
           design_version = dver,
           generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")) |>
    select(text_id, topic, topic_label, expressiveness, rating, replicate,
           persona, aspect, seed, text, model, temperature, design_version,
           generated_at)

  n_bad <- sum(is.na(res$text))
  # Duplicate rate is a first-class quality signal here, not an afterthought:
  # the v1 design looked fine on every other metric while 70% of its texts were
  # byte-identical. Print it every shard so a regression is visible immediately.
  n_dup <- sum(duplicated(res$text[!is.na(res$text)]))
  write_csv(res, f)

  done <- s * chunk
  eta  <- (as.numeric(difftime(Sys.time(), t_start, units = "mins")) / done) * (n - done)
  cat(sprintf("[%3d/%3d] %4d texts in %5.1fs | failed %3d | dup %3d (%.1f%%) | ETA %5.1f min\n",
              s, length(shards), nrow(res), dt, n_bad, n_dup,
              100 * n_dup / max(1, nrow(res)), eta))
  flush.console()
}

cat("\nMerging shards ...\n")
all <- lapply(list.files(out_dir, "\\.csv\\.gz$", full.names = TRUE), read_csv,
              show_col_types = FALSE) |> bind_rows()
# "raw" because a few requests always fail. src/repair_corpus.R fixes those
# and writes the finished reviews.csv.gz.
out_csv <- if (n_rep == design$full_corpus$n_replicates_per_cell) {
  "data/big/reviews_raw.csv.gz"
} else {
  sprintf("data/big/reviews_raw_%dper_cell.csv.gz", n_rep)
}
write_csv(all, out_csv)
cat(sprintf("Wrote %s : %d rows, %.1f MB\n",
            out_csv, nrow(all), file.size(out_csv) / 1e6))
cat(sprintf("Total elapsed: %.1f min\n", as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
