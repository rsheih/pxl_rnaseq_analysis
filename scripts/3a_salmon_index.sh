#!/bin/bash
#SBATCH --job-name=03_salmon_index
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 2                # Increased threads to match --nthread
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=16G
#SBATCH --output=/home/FCAM/rsheih/pxl_rnaseq/slurm/%x.%j.out  # Standard output log
#SBATCH --error=/home/FCAM/rsheih/pxl_rnaseq/slurm/%x.%j.err   # Standard error log

# Print job information
date
echo "Hostname: $(hostname)"

# Load required modules
module load salmon/1.9.0

# Set up directories

TRANSCRIPTOME="/home/FCAM/rsheih/pxl_rnaseq/genomes/gencode.v49.transcripts.fa"

INDEX="/home/FCAM/rsheih/pxl_rnaseq/genomes/salmon_index"

mkdir -p $INDEX

# run salmon index
salmon index \
        -t $TRANSCRIPTOME \
        -i $INDEX \
        -k 31 \
        -p 2
        --gencode

date

# Record end time
end_time=$(date +%s)  # Get timestamp in seconds

# Calculate runtime duration
runtime=$((end_time - start_time))
echo "Pipeline completed successfully."
echo "Total runtime: $((runtime / 60)) minutes and $((runtime % 60)) seconds."