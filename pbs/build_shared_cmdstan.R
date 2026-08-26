# CmdStan is a C++ toolchain, not an R package: ~15-25 min to build. Building
# it ONCE here, onto shared storage, is what saves every participant from
# doing it live on Thursday.
.libPaths(c("/storage/plzen1/home/chlupp/workshop/Rlibs", .libPaths()))
library(cmdstanr)
dir <- "/storage/plzen1/home/chlupp/workshop/cmdstan"
dir.create(dir, recursive = TRUE, showWarnings = FALSE)
install_cmdstan(dir = dir, cores = 4, quiet = FALSE, overwrite = FALSE)
p <- list.dirs(dir, recursive = FALSE)
p <- p[grepl("cmdstan-", basename(p))]
cat("CMDSTAN_BUILT_AT:", p, "\n")
set_cmdstan_path(p[1])
cat("version:", cmdstan_version(), "\n")
