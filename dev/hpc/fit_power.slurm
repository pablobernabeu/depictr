#!/bin/bash -l
#SBATCH --job-name=depictr-power
#SBATCH --partition=short
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=/data/educ-lift/educ1242/depictr/logs/power-%j.out
set -euo pipefail
module purge
module load R/4.5.1-gfbf-2025a
export R_LIBS_USER=/data/educ-lift/educ1242/depictr/r-library
OUT=/data/educ-lift/educ1242/depictr/model-outputs
mkdir -p "$OUT"
cd "$HOME/depictr"
echo "start=$(date) host=$(hostname)"
Rscript --no-save --no-restore dev/hpc/fit_power.R "$OUT"
echo "done=$(date)"
