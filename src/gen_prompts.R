# =============================================================================
# src/gen_prompts.R - the prompt factory (handover F3)
# =============================================================================
# The ONE place where a prompt is constructed. The design itself (topics,
# ratings, expressiveness levels, templates) lives in design/design.json, so
# the wording can be changed in one place without touching any code.
# =============================================================================

suppressPackageStartupMessages({
  library(jsonlite); library(tibble); library(dplyr); library(tidyr)
})

# Deterministic 31-bit hash of a string, computed in doubles to avoid R's
# integer overflow. Same id -> same seed, always.
.seed_from_id <- function(id) {
  cc <- as.integer(charToRaw(id))
  h  <- 0
  for (k in cc) h <- (h * 131 + k) %% 2147483647
  h
}

#' Load the design specification.
load_design <- function(path = file.path(dirname(getwd()), "design", "design.json")) {
  for (p in c(path, "design/design.json", "../design/design.json",
              "../../design/design.json")) {
    if (file.exists(p)) return(fromJSON(p, simplifyVector = FALSE))
  }
  stop("Cannot find design/design.json - run from the repo root.", call. = FALSE)
}

#' Build the prompt table.
#'
#' @param topics       character vector of topic ids, or NULL for all 25
#' @param ratings      integer vector of star ratings, or NULL for all five
#' @param n_replicates how many independent texts per (topic x rating) cell
#' @param design       result of load_design()
#' @return tibble(text_id, topic, topic_label, expressiveness, rating,
#'                replicate, system_prompt, user_prompt)
#'
#' NOTE ON THE DESIGN. Every text is generated from a KNOWN rating, so the
#' rating is the ground truth and the text is the noisy measurement of it. That
#' is deliberate: this is a simulation study, and in a simulation study you must
#' know the truth to check whether the method recovers it.
#' The one thing that makes it a real study rather than a tautology is the
#' `expressiveness` factor: topics differ in how openly the reviewer states the
#' verdict, so the strength of the text->rating relationship genuinely VARIES BY
#' TOPIC. That is what the hierarchical model's varying slopes are there to
#' estimate, and we can grade the answer because we designed the truth.
make_prompts <- function(topics = NULL,
                         ratings = NULL,
                         n_replicates = 10L,
                         design = load_design()) {

  all_topics <- bind_rows(lapply(design$topics, as_tibble))
  if (!is.null(topics)) {
    miss <- setdiff(topics, all_topics$topic)
    if (length(miss)) stop("Unknown topic(s): ", paste(miss, collapse = ", "), call. = FALSE)
    all_topics <- filter(all_topics, topic %in% topics)
  }
  if (is.null(ratings)) ratings <- unlist(design$ratings)

  grid <- expand_grid(
    topic     = all_topics$topic,
    rating    = as.integer(ratings),
    replicate = seq_len(n_replicates)
  ) |>
    left_join(all_topics, by = "topic") |>
    mutate(
      rating_label   = vapply(as.character(rating),
                              function(r) design$rating_labels[[r]], character(1)),
      expr_instruction = vapply(expressiveness,
                              function(e) design$expressiveness[[e]], character(1)),

      # ---- nuisance variation (design v2) ---------------------------------
      # v1 gave every replicate in a cell a byte-identical prompt, and the model
      # collapsed to ~6 distinct completions per 20 requests. Injecting a
      # reviewer persona and a review aspect fixes that AND makes the corpus
      # look like a real one, where reviewers and their concerns differ.
      #
      # Both are chosen from the REPLICATE INDEX ONLY, with strides coprime to
      # the list lengths (7 and 11 against 20). That guarantees they are spread
      # evenly across every topic x rating cell, so they add within-cell noise
      # without confounding the designed factors.
      persona = vapply(replicate, function(i)
                  design$personas[[((i * 7L) %% length(design$personas)) + 1L]],
                  character(1)),
      aspect  = vapply(replicate, function(i)
                  design$aspects[[((i * 11L) %% length(design$aspects)) + 1L]],
                  character(1)),

      user_prompt = design$user_template |>
        (\(tpl) mapply(function(p, rl, ei, pe, as) {
          x <- gsub("{product}",       p,  tpl, fixed = TRUE)
          x <- gsub("{rating_label}",  rl, x,   fixed = TRUE)
          x <- gsub("{persona}",       pe, x,   fixed = TRUE)
          x <- gsub("{aspect}",        as, x,   fixed = TRUE)
          gsub("{expressiveness_instruction}", ei, x, fixed = TRUE)
        }, label, rating_label, expr_instruction, persona, aspect, USE.NAMES = FALSE))(),
      system_prompt = design$system_prompt
    ) |>
    arrange(topic, rating, replicate) |>
    mutate(text_id = sprintf("%s_r%d_%03d", topic, rating, replicate), .before = 1) |>
    # A per-request seed decorrelates any two requests that still happen to
    # share a prompt. Verified: identical prompt + varying seed gave 5/5
    # distinct completions, where identical prompt alone gave 2/5.
    # Derived deterministically from text_id (a simple polynomial rolling hash
    # in doubles - R's 32-bit integers overflow long before this finishes), so
    # the whole corpus is reproducible from the design alone.
    mutate(seed = vapply(text_id, .seed_from_id, double(1), USE.NAMES = FALSE))

  select(grid, text_id, topic, topic_label = label, expressiveness,
         rating, replicate, persona, aspect, seed, system_prompt, user_prompt)
}

#' The 60-text slice a participant generates live in Block 2.
#' Participants pick their own 3 topics so the room does not all send the same
#' prompts at the same instant.
make_live_prompts <- function(topics, design = load_design()) {
  ls <- design$live_slice
  stopifnot(length(topics) == ls$n_topics)
  make_prompts(topics = topics,
               ratings = unlist(ls$ratings),
               n_replicates = ls$n_replicates,
               design = design)
}
