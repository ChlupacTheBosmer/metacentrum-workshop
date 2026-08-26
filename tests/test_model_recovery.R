# =============================================================================
# tests/test_model_recovery.R - does the Stan model recover known truth?
# =============================================================================
# Decision D8 removed the supervisor review, so the model has to earn trust by
# evidence instead of authority. This is that evidence: we simulate data from
# the EXACT generative process the model assumes, with parameters we choose,
# then check the posterior covers them.
#
# If this fails, the model is wrong. If it passes, the model is at least
# self-consistent - which is the necessary condition before pointing it at real
# embeddings.
#
# Usage:  Rscript tests/test_model_recovery.R [n_obs] [chains]
# =============================================================================

suppressPackageStartupMessages({ library(cmdstanr); library(posterior) })

# Find Stan, the same way every other script does.
source("config.R")
source("src/stan_setup.R")
ensure_stan_is_found()

set.seed(42)

args   <- commandArgs(trailingOnly = TRUE)
N      <- if (length(args) >= 1) as.integer(args[1]) else 2000L
chains <- if (length(args) >= 2) as.integer(args[2]) else 4L

J <- 25L; K <- 30L; P <- 3L; C <- 5L; M <- P + 1L

# ---- ground truth -----------------------------------------------------------
beta_true <- c(1.2, -0.8, 0.5, rnorm(K - 3, 0, 0.15))   # PC1-3 matter, rest noise
tau_true  <- c(0.7, 0.5, 0.3, 0.2)                       # intercept + 3 slopes
c_true    <- c(-2.2, -0.7, 0.7, 2.2)                     # 4 cutpoints, 5 categories

Omega_true <- diag(M)
Omega_true[1, 2] <- Omega_true[2, 1] <- 0.4              # topics with higher
                                                         # baseline also steeper
L_true <- t(chol(Omega_true))
u_true <- (diag(tau_true) %*% L_true) %*% matrix(rnorm(M * J), M, J)

# ---- simulate ---------------------------------------------------------------
topic <- sample.int(J, N, replace = TRUE)
x     <- matrix(rnorm(N * K), N, K)                      # standardised by construction

eta <- as.vector(x %*% beta_true)
for (n in seq_len(N)) {
  j <- topic[n]
  eta[n] <- eta[n] + u_true[1, j] + sum(u_true[2:M, j] * x[n, 1:P])
}

# ordered logistic: P(y <= k) = logistic(c_k - eta)
rord <- function(eta_n, cuts) {
  cum <- plogis(cuts - eta_n)
  p   <- diff(c(0, cum, 1))
  sample.int(length(p), 1, prob = p)
}
y <- vapply(eta, rord, integer(1), cuts = c_true)

cat(sprintf("simulated N=%d, J=%d, K=%d, P=%d\ncategory counts: %s\n\n",
            N, J, K, P, paste(table(y), collapse = " ")))

# ---- fit --------------------------------------------------------------------
# Find the model file. Run this from the repository root, which is where
# every other script also expects to be run from.
model_path <- "09_model/model.stan"

if (!file.exists(model_path)) {
  stop("Cannot find ", model_path, ".\n",
       "  Run this from the repository root, like this:\n",
       "      Rscript tests/test_model_recovery.R")
}

mod <- cmdstan_model(model_path)

t0 <- Sys.time()
fit <- mod$sample(
  data = list(N = N, J = J, K = K, P = P, C = C, topic = topic, y = y, x = x),
  chains = chains, parallel_chains = chains,
  iter_warmup = 1000, iter_sampling = 1000,
  refresh = 250, show_messages = FALSE
)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))

# ---- diagnostics ------------------------------------------------------------
cat(sprintf("\nfit took %.2f min on %d chains\n", elapsed, chains))
d <- fit$sampler_diagnostics()
cat(sprintf("divergent transitions: %d\nmax treedepth hits : %d\n",
            sum(d[, , "divergent__"]), sum(d[, , "treedepth__"] >= 10)))

# ---- recovery ---------------------------------------------------------------
check <- function(name, truth, draws) {
  q <- quantile(draws, c(0.025, 0.975))
  inside <- truth >= q[1] && truth <= q[2]
  cat(sprintf("  %-18s truth %7.3f   95%% CI [%7.3f, %7.3f]  %s\n",
              name, truth, q[1], q[2], if (inside) "ok" else "*** MISSED ***"))
  inside
}
dr <- fit$draws(format = "df")
ok <- c(
  check("beta[1]", beta_true[1], dr$`beta[1]`),
  check("beta[2]", beta_true[2], dr$`beta[2]`),
  check("beta[3]", beta_true[3], dr$`beta[3]`),
  check("tau[1] (intcpt)", tau_true[1], dr$`tau[1]`),
  check("tau[2] (PC1 slope)", tau_true[2], dr$`tau[2]`),
  check("tau[3] (PC2 slope)", tau_true[3], dr$`tau[3]`),
  check("c[1]", c_true[1], dr$`c[1]`),
  check("c[4]", c_true[4], dr$`c[4]`),
  check("Omega[1,2]", Omega_true[1, 2], dr$`Omega[1,2]`)
)
cat(sprintf("\nrecovered %d/%d parameters inside the 95%% credible interval\n",
            sum(ok), length(ok)))
rh <- fit$summary(c("beta", "tau", "c"))$rhat
cat(sprintf("max R-hat across beta/tau/c: %.4f\n", max(rh, na.rm = TRUE)))
if (sum(ok) < length(ok) - 1) quit(status = 1)
