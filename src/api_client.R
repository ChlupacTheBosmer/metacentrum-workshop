# =============================================================================
# src/api_client.R - thin, honest wrapper over the e-INFRA OpenAI-compatible API
# =============================================================================
# Handover F2. Design rules this file obeys:
#   * No URL, model ID or key is hardcoded here. Everything comes from config.R
#     or the environment.
#   * The API key is read from an environment variable and is NEVER printed,
#     logged, or written to disk. It is also REDACTED out of error messages,
#     because this API echoes the key back inside HTTP 429 error bodies.
#   * Requests are capped at 4 in flight. This is not a guess: the server sends
#     `x-ratelimit-api_key-limit-max_parallel_requests: 4` and returns HTTP 429
#     beyond it. Verified 2026-08-23.
#   * chat() HARD FAILS on empty content instead of returning "". Several models
#     on this endpoint are reasoning models that spend the whole token budget on
#     hidden reasoning and hand back an empty message. Silently writing those to
#     a CSV would give you a corpus of blank rows.
# =============================================================================

suppressPackageStartupMessages({
  library(httr2)
  library(tibble)
  library(dplyr)
  library(purrr)
})

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- key handling -----------------------------------------------------------

#' Fetch the API key from the environment. Never returns it in an error.
api_key <- function(var = cfg$ai$key_env_var) {
  k <- Sys.getenv(var, unset = "")
  if (!nzchar(k)) {
    stop(
      "No API key found in environment variable '", var, "'.\n",
      "  Get one at ", cfg$ai$webui_url, " -> Settings -> Account -> API keys,\n",
      "  then add this line to ~/.Renviron (NOT to any file in this repo):\n",
      "      ", var, "=your_key_here\n",
      "  and restart R (Session -> Restart R).",
      call. = FALSE
    )
  }
  k
}

#' Remove anything that looks like the key from a string before showing it.
redact <- function(txt, key = Sys.getenv(cfg$ai$key_env_var, unset = "")) {
  if (nzchar(key)) txt <- gsub(key, "<REDACTED_KEY>", txt, fixed = TRUE)
  # the 429 body echoes the key after "api_key:" even when it is hashed
  gsub("(api_key:\\s*)[A-Za-z0-9._-]+", "\\1<REDACTED>", txt)
}

# ---- request construction ---------------------------------------------------

# A tiny counter so the bounded backoff grows across attempts. httr2 calls
# `after` once per retry; it does not pass the attempt number, so we track it.
.retry_env <- new.env(parent = emptyenv())
.retry_n <- function() {
  n <- (.retry_env$n %||% 0) + 1
  if (n > 6) n <- 6
  .retry_env$n <- n
  n
}
.retry_reset <- function() .retry_env$n <- 0

.base_req <- function(path) {
  request(cfg$ai$base_url) |>
    req_url_path_append(path) |>
    req_headers(Authorization = paste(cfg$ai$auth_scheme, api_key())) |>
    req_user_agent("workshop-metacentrum-r") |>
    req_timeout(180) |>
    # Retry transient failures. 429 here means "too many in flight", so backing
    # off and retrying is exactly the right response.
    # ---- retry policy, and the single most important line in this file ------
    # The server answers a parallel-limit rejection with `Retry-After: 1800`.
    # That number is a lie: it is LiteLLM's generic default, not a real 30-minute
    # penalty. Verified 2026-08-23 - while four requests were being rejected with
    # Retry-After: 1800, two *other* requests on the same key returned HTTP 200
    # in the same second. The limit is on requests IN FLIGHT, not per time window.
    #
    # httr2 honours Retry-After by default, so without the `after` override below
    # a single 429 freezes your R session for thirty minutes. Supplying `after`
    # makes httr2 ignore the header and use our own bounded backoff instead.
    req_retry(
      max_tries = cfg$ai$max_retries,
      is_transient = function(resp) resp_status(resp) %in% c(429, 500, 502, 503, 504),
      after = function(resp) min(2^(.retry_n()), cfg$ai$backoff_max_sec) + runif(1, 0, 0.5)
    ) |>
    req_error(body = function(resp) redact(resp_body_string(resp)))
}

# ---- chat -------------------------------------------------------------------

#' One chat completion. Returns the message text as a length-1 character.
#' Errors (never returns "") if the model produced no visible content.
chat <- function(user,
                 system = NULL,
                 model = cfg$ai$chat_model,
                 temperature = 1.0,
                 max_tokens = 220L) {

  if (model %in% cfg$ai$chat_models_unsafe) {
    stop("Model '", model, "' is a reasoning model on this endpoint: it returns ",
         "an empty message when max_tokens is capped. Use cfg$ai$chat_model ",
         "('", cfg$ai$chat_model, "') for text generation.", call. = FALSE)
  }

  msgs <- c(
    if (!is.null(system)) list(list(role = "system", content = system)),
    list(list(role = "user", content = user))
  )

  resp <- .base_req("chat/completions") |>
    req_body_json(list(model = model, messages = msgs,
                       temperature = temperature, max_tokens = max_tokens)) |>
    req_perform() |>
    resp_body_json()

  .extract_text(resp, model)
}

.extract_text <- function(resp, model) {
  txt <- resp$choices[[1]]$message$content
  if (is.null(txt) || !nzchar(trimws(txt))) {
    fin <- resp$choices[[1]]$finish_reason %||% "?"
    stop("Model '", model, "' returned EMPTY content (finish_reason='", fin, "').\n",
         "  This is the reasoning-model trap: the token budget went to hidden\n",
         "  reasoning. Pick a non-reasoning model - see cfg$ai$chat_models_unsafe.",
         call. = FALSE)
  }
  trimws(txt)
}

#' Many chat completions, at most `concurrency` in flight.
#' Returns a character vector the same length as `user`, in the same order.
#'
#' THE CACHE, and why it matters more than it sounds.
#' This endpoint caches responses keyed on the request body. Send the same
#' prompt twice and you get back the SAME response - same text, same response
#' `id`, and in ~0.1s instead of ~0.9s. Measured 2026-08-24: four identical
#' requests returned one distinct text and one distinct id.
#'
#' For a chat application that is a feature. For generating a SIMULATION STUDY
#' it is a silent catastrophe: our first 50k corpus came back ~70% exact
#' duplicates, which is pseudo-replication dressed up as sample size.
#'
#' Two ways to defeat it, both verified:
#'   * give each request a distinct `seed` - the seed is part of the cache key,
#'     so distinct seeds always miss the cache (4/4 distinct texts and ids);
#'   * set `no_cache = TRUE`, which sends {"cache": {"no-cache": true}}
#'     (3/3 distinct with no seed at all).
#' The corpus generator uses distinct seeds; `no_cache` is here for the case
#' where you genuinely need to resend an identical request.
chat_many <- function(user,
                      system = NULL,
                      model = cfg$ai$chat_model,
                      temperature = 1.0,
                      max_tokens = 220L,
                      seed = NULL,          # optional per-request seeds
                      no_cache = FALSE,     # explicitly bypass the server cache
                      concurrency = cfg$ai$chat_concurrency,
                      progress = TRUE) {

  stopifnot(is.character(user), length(user) > 0)
  if (concurrency > 4L) {
    warning("concurrency=", concurrency, " exceeds the server's verified cap of 4 ",
            "parallel requests per key; you will see HTTP 429. Clamping to 4.")
    concurrency <- 4L
  }

  if (!is.null(seed)) stopifnot(length(seed) == length(user))

  reqs <- lapply(seq_along(user), function(i) {
    msgs <- c(
      if (!is.null(system)) list(list(role = "system", content = system)),
      list(list(role = "user", content = user[i]))
    )
    body <- list(model = model, messages = msgs,
                 temperature = temperature, max_tokens = max_tokens)
    # A per-request seed. This endpoint honours it: identical prompts with
    # differing seeds returned 5/5 distinct completions, where the same prompt
    # without a seed returned only 2/5. Without this, a 50k corpus collapses
    # into a few thousand repeated texts.
    if (!is.null(seed)) body$seed <- as.integer(seed[i] %% 2147483647)
    # Belt-and-braces against the server-side response cache (see below).
    if (isTRUE(no_cache)) body$cache <- list(`no-cache` = TRUE)
    .base_req("chat/completions") |> req_body_json(body)
  })

  resps <- req_perform_parallel(reqs, max_active = concurrency,
                                on_error = "continue", progress = progress)

  vapply(seq_along(resps), function(i) {
    r <- resps[[i]]
    if (inherits(r, "error") || is.null(r)) return(NA_character_)
    tryCatch(.extract_text(resp_body_json(r), model), error = function(e) NA_character_)
  }, character(1))
}

# ---- embeddings -------------------------------------------------------------

#' Embed a character vector. Returns a numeric matrix: one row per text.
#' Texts are sent in batches; a batch is one request, so batching is the cheap
#' way to go fast without touching the 4-parallel-request cap.
embed <- function(texts,
                  model = cfg$ai$embed_model,
                  batch_size = cfg$ai$embed_batch_size,
                  progress = TRUE) {

  stopifnot(is.character(texts), length(texts) > 0)
  idx    <- split(seq_along(texts), ceiling(seq_along(texts) / batch_size))
  out    <- vector("list", length(idx))

  for (b in seq_along(idx)) {
    resp <- .base_req("embeddings") |>
      req_body_json(list(model = model, input = as.list(texts[idx[[b]]]))) |>
      req_perform() |>
      resp_body_json()
    out[[b]] <- do.call(rbind, lapply(resp$data, function(d) unlist(d$embedding)))
    if (progress) cat(sprintf("\r  embedded %d/%d", max(idx[[b]]), length(texts)))
  }
  if (progress) cat("\n")

  m <- do.call(rbind, out)
  if (nrow(m) != length(texts)) {
    stop("Embedding returned ", nrow(m), " vectors for ", length(texts), " texts.",
         call. = FALSE)
  }
  if (ncol(m) != cfg$ai$embed_dim) {
    warning("Embedding dimension is ", ncol(m), " but config says ",
            cfg$ai$embed_dim, ". Update cfg$ai$embed_dim.")
  }
  m
}

# ---- small helpers ----------------------------------------------------------

#' Cosine similarity between one vector and the rows of a matrix.
cosine_sim <- function(v, m) {
  as.vector((m %*% v) / (sqrt(rowSums(m^2)) * sqrt(sum(v^2))))
}

#' Smoke test: proves the key works, the endpoint is reachable, and the chosen
#' models behave. Run this FIRST in Block 2 - it turns five separate failure
#' modes into one clear message.
api_smoke_test <- function() {
  cat("1. key present in $", cfg$ai$key_env_var, " ... ", sep = "")
  invisible(api_key()); cat("ok\n")

  cat("2. chat model '", cfg$ai$chat_model, "' ... ", sep = "")
  t <- system.time(txt <- chat("Say the single word: ready.",
                               system = "Reply with one word only.",
                               max_tokens = 20L))[["elapsed"]]
  cat(sprintf("ok (%.1fs) -> %s\n", t, substr(txt, 1, 40)))

  cat("3. embedding model '", cfg$ai$embed_model, "' ... ", sep = "")
  t <- system.time(m <- embed(c("a", "b"), progress = FALSE))[["elapsed"]]
  cat(sprintf("ok (%.1fs) -> %d x %d\n", t, nrow(m), ncol(m)))

  cat("\nAll three checks passed. You are ready for Block 2.\n")
  invisible(TRUE)
}


# ---- surviving a model disappearing ----------------------------------------

#' Find a chat model that actually works, right now.
#'
#' Why this exists: the model this workshop was built on vanished from the
#' service overnight. One day it answered, the next it returned HTTP 403
#' "Model is blocked". Two of its replacements answered HTTP 200 with empty
#' text, which is harder to notice.
#'
#' So rather than trusting the configured name, we try it, and if it does not
#' produce usable text we walk down the list of backups until one does.
#'
#' @return the name of a model that responded with real text
pick_working_model <- function(candidates = c(cfg$ai$chat_model,
                                              cfg$ai$chat_model_backup)) {

  for (model_name in candidates) {

    # Ask for one short word. Cheap, and enough to prove it works.
    result <- tryCatch(
      chat("Say the single word: ready.",
           system = "Reply with one word only.",
           model = model_name,
           max_tokens = 20L),
      error = function(e) NULL
    )

    # chat() already refuses to return empty text, so anything non-NULL is good.
    if (!is.null(result)) {
      return(model_name)
    }

    message("model '", model_name, "' is not usable right now, trying the next one")
  }

  stop("None of these models worked: ", paste(candidates, collapse = ", "),
       "\n  Check the current list at https://chat.ai.e-infra.cz",
       call. = FALSE)
}
