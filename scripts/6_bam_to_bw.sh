#!/bin/bash
#SBATCH --job-name=06_bam_to_bw
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --mem=12G
#SBATCH -p general
#SBATCH --qos=general
#SBATCH -o /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.out
#SBATCH -e /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.err

set -e

start_time=$(date +%s)

date
echo "host name: $(hostname)"

module load deeptools/3.5.0

mkdir -p "/home/FCAM/rsheih/pxl_rnaseq/out_bw_2"

cd /home/FCAM/rsheih/pxl_rnaseq/bam_sorted

# Loop directly over .bam files
for bam_file in *.bam; do
    # Extract the base name without extension
    base_name=$(basename "$bam_file" .bam)

    # Construct the output filename
    output_file="/home/FCAM/rsheih/pxl_rnaseq/out_bw_2/${base_name}.bw"
    bamCoverage --normalizeUsing CPM -b "$bam_file" -o "$output_file"
done

date

end_time=$(date +%s)
runtime=$((end_time - start_time))

echo "Pipeline completed successfully."
echo "Total runtime: $((runtime / 60)) minutes and $((runtime % 60)) seconds."