#!/bin/bash
#SBATCH --job-name=run_pipeline
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -p general
#SBATCH --qos=general
#SBATCH --mem=64G
#SBATCH -o /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.out
#SBATCH -e /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.err

set -e

cd /home/FCAM/rsheih/pxl_rnaseq

bash scripts/1_get_files.sh
bash scripts/2_process.sh /home/FCAM/rsheih/pxl_rnaseq/data/raw
bash scripts/3a_salmon_index.sh
bash scripts/3b_star_index.sh
bash scripts/4a_run_salmon.sh
bash scripts/4b_run_star.sh
bash scripts/5_coordinate_sorting.sh
bash scripts/6_bam_to_bw.sh

echo "Pipeline completed!"
