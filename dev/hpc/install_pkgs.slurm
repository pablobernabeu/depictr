#!/bin/bash -l
#SBATCH --job-name=depictr-pkgs
#SBATCH --partition=short
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --output=/data/educ-lift/educ1242/depictr/logs/install-%j.out

# Build the depictr R environment in the project DATA space (not HOME).
# Installs depictr's deps plus the modelling/Bayesian stack used by the
# revision (brms/rstan/rstanarm, ggdist/posterior/tidybayes/bayesplot,
# lme4/lmerTest/simr/survival) and dev tooling.
set -euo pipefail
module purge
module load R/4.5.1-gfbf-2025a
export R_LIBS_USER=/data/educ-lift/educ1242/depictr/r-library
export MAKEFLAGS="-j${SLURM_CPUS_PER_TASK:-8}"
mkdir -p "$R_LIBS_USER"
echo "host=$(hostname) R=$(command -v R) lib=$R_LIBS_USER start=$(date)"

Rscript --no-save --no-restore - <<'RS'
options(Ncpus = 2L, repos = c(CRAN = "https://cloud.r-project.org"), warn = 1)
pkgs <- c(
  # depictr hard deps
  "ggplot2","stringr","scales","patchwork","rlang","Rdpack",
  # modelling back-ends + survival
  "lme4","lmerTest","broom","broom.mixed","simr","survival",
  # Bayesian / posterior stack (flagship posterior layer + expansions)
  "posterior","ggdist","bayesplot","tidybayes","rstan","brms","rstanarm",
  # dev / test / docs
  "testthat","roxygen2","devtools","vdiffr","covr","pkgdown"
)
have <- rownames(installed.packages())
need <- setdiff(pkgs, have)
cat("to install (", length(need), "):", paste(need, collapse = ", "), "\n")
if (length(need)) install.packages(need)
cat("\n=== resulting versions ===\n")
for (p in pkgs) cat(sprintf("%-12s %s\n", p,
  tryCatch(as.character(packageVersion(p)), error = function(e) "** FAILED **")))
cat("\nfinished:", format(Sys.time()), "\n")
RS
echo "job-done=$(date)"
