#!/bin/bash
#SBATCH --job-name=04_run_star
#SBATCH -N 1                    # number of nodes (always 1)
#SBATCH -n 1                    # number of jobs / tasks (always 1)
#SBATCH -c 4                    # number of cores (1-4)
#SBATCH -p general              # SLURM partition (always mcbstudent)
#SBATCH --qos=general           # SLURM Quality of service (always mcbstudent)
#SBATCH --mem=24G               # RAM (memory) requested 
#SBATCH -o /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.out
#SBATCH -e /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.err

set -e  # Exit immediately if any command fails (important for debugging)

# Record start time
start_time=$(date +%s)  # Get timestamp in seconds


date
echo "host name : " `hostname`

module load STAR/2.7.11a
module load IGVtools/2.9.1


IN="/home/FCAM/rsheih/pxl_rnaseq/data/processed"
OUT="/home/FCAM/rsheih/pxl_rnaseq/star_out"
GENOME="/home/FCAM/rsheih/pxl_rnaseq/genomes/star_index"

mkdir -p "$OUT"

SAMPLES="/home/FCAM/rsheih/pxl_rnaseq/data/processed/list_4.txt" # just basenames


while IFS= read -r sample; do
        STAR --runThreadN 4 \
        --genomeDir $GENOME \
        --readFilesIn $IN/${sample}_trim.fastq.gz \
        --readFilesCommand zcat \
        --outFileNamePrefix $OUT/${sample} \
        --outSAMtype BAM SortedByCoordinate \
        --outBAMsortingThreadN 4 \
        --outFilterType BySJout \
        --outFilterMultimapNmax 20 \
        --alignSJoverhangMin 8 \
        --alignSJDBoverhangMin 1 \
        --outFilterMismatchNmax 999 \
        --outFilterMismatchNoverReadLmax 0.04 \
        --alignIntronMin 20 \
        --alignIntronMax 300000 \
        --alignMatesGapMax 300000
        if [ $? -eq 0 ]; then
                echo "STAR alignment for ${sample} succeeded, proceeding to rename and index."
                mv "${OUT}/${sample}Aligned.sortedByCoord.out.bam" "${OUT}/${sample}.bam"
                igvtools index ${OUT}/${sample}.bam
        else
                echo "STAR alignment for ${sample} failed, skipping rename and index steps."
        fi
done < "$SAMPLES"

date

# Record end time
end_time=$(date +%s)  # Get timestamp in seconds

# Calculate runtime duration
runtime=$((end_time - start_time))
echo "Pipeline completed successfully."
echo "Total runtime: $((runtime / 60)) minutes and $((runtime % 60)) seconds."