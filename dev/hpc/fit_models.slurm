#!/bin/bash -l
#SBATCH --job-name=depictr-fit
#SBATCH --partition=short
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=/data/educ-lift/educ1242/depictr/logs/fit-%j.out
set -euo pipefail

# Site-specific project space. Override at submission time with
#   PROJECT_ROOT=/your/project/depictr sbatch dev/hpc/fit_models.slurm
# The #SBATCH --output path above has to be edited by hand: Slurm reads the
# directives before the shell runs, so it does not expand variables in them.
PROJECT_ROOT="${PROJECT_ROOT:-/data/educ-lift/educ1242/depictr}"

module purge
module load R/4.5.1-gfbf-2025a
export R_LIBS_USER="$PROJECT_ROOT/r-library"
OUT="$PROJECT_ROOT/model-outputs"
mkdir -p "$OUT"
cd "$HOME/depictr"
echo "start=$(date) host=$(hostname)"
Rscript --no-save --no-restore dev/hpc/fit_models.R "$OUT"
echo "done=$(date)"
