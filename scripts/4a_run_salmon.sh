#!/bin/bash
#BATCH --job-name=quant_Salmon
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 4   
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mail-type=END
#SBATCH --mem=8G
#SBATCH --mail-user=YOU@uchc.edu
#SBATCH --output=/home/FCAM/rsheih/pxl_rnaseq/slurm/%x.%j.out  # Standard output log
#SBATCH --error=/home/FCAM/rsheih/pxl_rnaseq/slurm/%x.%j.err   # Standard error log

# Print job information

set -e  # Exit immediately if any command fails (important for debugging)

# Record start time
start_time=$(date +%s)  # Get timestamp in seconds


date
echo "Hostname: $(hostname)"

module load salmon/1.9.0

# Directory containing the FASTQ files
FASTQ_DIR="/home/FCAM/rsheih/pxl_rnaseq/data/processed"

# Directory to store the output of salmon quant
OUTPUT_DIR="/home/FCAM/rsheih/pxl_rnaseq/salmon_quant"

# Path to the salmon index

SALMON_INDEX="/home/FCAM/rsheih/pxl_rnaseq/genomes/salmon_index"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through all the .fastq.gz files in the directory

for fq in ${FASTQ_DIR}/*_trim.fastq.gz; do

    sample=$(basename "$fq" _1.fastq.gz)
    
    echo "Processing sample: $sample"
    
    salmon quant \
        -i $SALMON_INDEX \
        -l A \
        -r $fq \
        -p 4 \
        --validateMappings \
        -o ${OUTPUT_DIR}/${sample}
    
done

echo "Salmon quantification completed for all samples."

# Record end time
end_time=$(date +%s)  # Get timestamp in seconds

# Calculate runtime duration
runtime=$((end_time - start_time))
echo "Pipeline completed successfully."
echo "Total runtime: $((runtime / 60)) minutes and $((runtime % 60)) seconds."