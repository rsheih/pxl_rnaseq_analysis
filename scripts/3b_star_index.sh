#!/bin/bash
#SBATCH --job-name=03_star_index
#SBATCH -N 1                    # number of nodes (always 1)
#SBATCH -n 1                    # number of jobs / tasks (always 1)
#SBATCH -c 4                    # number of cores (1-4)
#SBATCH -p general              # SLURM partition (always mcbstudent)
#SBATCH --qos=general           # SLURM Quality of service (always mcbstudent)
#SBATCH --mem=64G               # RAM (memory) requested 
#SBATCH -o /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.out
#SBATCH -e /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.err

set -e  # Exit immediately if any command fails (important for debugging)

# Record start time
start_time=$(date +%s)  # Get timestamp in seconds


date
echo "host name : " `hostname`

module load STAR/2.7.11a

GENOME_DIR="/home/FCAM/rsheih/pxl_rnaseq/genomes/star_index"
FASTA="/home/FCAM/rsheih/pxl_rnaseq/genomes/GRCh38.primary_assembly.genome.fa"
GTF="/home/FCAM/rsheih/pxl_rnaseq/genomes/gencode.v44.annotation.gtf"

mkdir -p "$GENOME_DIR"

echo "Building STAR genome index..."
echo "FASTA: $FASTA"
echo "GTF: $GTF"

STAR \
  --runThreadN 8 \
  --runMode genomeGenerate \
  --genomeDir $GENOME_DIR \
  --genomeFastaFiles $FASTA \
  --sjdbGTFfile $GTF \

echo "STAR index completed."

date

# Record end time
end_time=$(date +%s)  # Get timestamp in seconds

# Calculate runtime duration
runtime=$((end_time - start_time))
echo "Pipeline completed successfully."
echo "Total runtime: $((runtime / 60)) minutes and $((runtime % 60)) seconds."