#!/bin/bash -l
#SBATCH --job-name=depictr-fit
#SBATCH --partition=short
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=/data/educ-lift/educ1242/depictr/logs/fit-%j.out
set -euo pipefail
module purge
module load R/4.5.1-gfbf-2025a
export R_LIBS_USER=/data/educ-lift/educ1242/depictr/r-library
OUT=/data/educ-lift/educ1242/depictr/model-outputs
mkdir -p "$OUT"
cd "$HOME/depictr"
echo "start=$(date) host=$(hostname)"
Rscript --no-save --no-restore dev/hpc/fit_models.R "$OUT"
echo "done=$(date)"
