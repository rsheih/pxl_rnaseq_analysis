#!/bin/bash
#SBATCH --job-name=05_sort_bam
#SBATCH -N 1                    # number of nodes (always 1)
#SBATCH -n 1                    # number of jobs / tasks (always 1)
#SBATCH -c 4                    # number of cores (1-4)
#SBATCH -p general              # SLURM partition (always mcbstudent)
#SBATCH --qos=general           # SLURM Quality of service (always mcbstudent)
#SBATCH --mem=6G               # RAM (memory) requested 
#SBATCH -o /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.out
#SBATCH -e /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.err

set -e  # Exit immediately if any command fails (important for debugging)

# Record start time
start_time=$(date +%s)  # Get timestamp in seconds


date
echo "host name : " `hostname`

module load samtools

inDir="/home/FCAM/rsheih/pxl_rnaseq/star_out"
outDir="/home/FCAM/rsheih/pxl_rnaseq/star_out/bam_sorted"

mkdir -p $outDir 


for file in "$inDir"/*.bam
do
    echo sorting $file
    prefix=$(basename "${file}" .bam)
    samtools view $file -o ${prefix}.bam
    samtools sort ${prefix}.bam -o "$outDir"/${prefix}_sorted.bam
    samtools index "$outDir/${prefix}_sorted.bam"
done

date

# Record end time
end_time=$(date +%s)  # Get timestamp in seconds

# Calculate runtime duration
runtime=$((end_time - start_time))
echo "Pipeline completed successfully."
echo "Total runtime: $((runtime / 60)) minutes and $((runtime % 60)) seconds."