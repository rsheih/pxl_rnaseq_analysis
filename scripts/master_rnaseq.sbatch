#!/usr/bin/env bash
#SBATCH --job-name=pxl_submit
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:10:00
#SBATCH --output=pxl_submit_%j.out

# Submit once with: sbatch scripts/master_rnaseq.sbatch
# This file ONLY schedules existing numbered scripts; no analysis commands live here.
# Each stage runs as a separate SLURM job, after the previous one succeeds.
# Completed stages have .done files and are skipped on later submissions.

set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/home/FCAM/rsheih/pxl_rnaseq}"
SCRIPT_DIR="${SCRIPT_DIR:-${SLURM_SUBMIT_DIR:-$PWD}/scripts}"
RAW_DIR="${RAW_DIR:-$PROJECT_DIR/data/raw}"
CHECKPOINT_DIR="${CHECKPOINT_DIR:-$PROJECT_DIR/checkpoints/master}"
LOG_DIR="${LOG_DIR:-$PROJECT_DIR/slurm}"
RUN_UNZIP="${RUN_UNZIP:-0}" # 1 to submit script 1; 0 if FASTQs already extracted

mkdir -p "$CHECKPOINT_DIR" "$LOG_DIR"
previous_job=""

submit_stage() {
  local label="$1" script="$2" cpus="$3" mem="$4" time="$5" arg="${6:-}"
  local marker="$CHECKPOINT_DIR/${label}.done"
  local script_path="$SCRIPT_DIR/$script"
  [[ -f "$script_path" ]] || { echo "Missing script: $script_path" >&2; exit 1; }

  # Skip only stages with completed markers.
  if [[ -f "$marker" ]]; then
    echo "SKIP completed stage: $label"
    return
  fi

  local dependency=()
  if [[ -n "$previous_job" ]]; then
    dependency=("--dependency=afterok:$previous_job")
  fi

  # The individual #SBATCH directives are ignored when running under bash,
  # so the requests are supplied here.
  local wrapped
  if [[ -n "$arg" ]]; then
    printf -v wrapped 'set -e; bash %q %q && touch %q' "$script_path" "$arg" "$marker"
  else
    printf -v wrapped 'set -e; bash %q && touch %q' "$script_path" "$marker"
  fi
  previous_job="$(sbatch --parsable \
    --job-name="pxl_$label" \
    --partition=general --qos=general \
    --nodes=1 --ntasks=1 --cpus-per-task="$cpus" \
    --mem="$mem" --time="$time" \
    --chdir="$PROJECT_DIR" \
    --output="$LOG_DIR/${label}_%j.out" \
    --error="$LOG_DIR/${label}_%j.err" \
    "${dependency[@]}" --wrap="$wrapped")"
  echo "SUBMITTED $label: job $previous_job"
}

if [[ "$RUN_UNZIP" == 1 ]]; then
  submit_stage "01_unzip" "1_get_files.sh" 1 8G 02:00:00
fi
submit_stage "02_process" "2_process.sh" 4 8G 12:00:00 "$RAW_DIR"
submit_stage "03a_salmon_index" "3a_salmon_index.sh" 2 16G 08:00:00
submit_stage "03b_star_index" "3b_star_index.sh" 8 64G 12:00:00
submit_stage "04a_salmon" "4a_run_salmon.sh" 4 8G 12:00:00
submit_stage "04b_star" "4b_run_star.sh" 4 24G 24:00:00
submit_stage "05_sort" "5_coordinate_sorting.sh" 4 6G 12:00:00
submit_stage "06_bigwig" "6_bam_to_bw.sh" 4 12G 12:00:00

echo "All incomplete stages queued. Inspect with: squeue -u $USER"
echo "Checkpoints: $CHECKPOINT_DIR"
