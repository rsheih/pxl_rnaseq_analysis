#!/bin/bash -l

#SBATCH --job-name=2_process.sh     # name for job
#SBATCH -N 1                    # number of nodes (always 1)
#SBATCH -n 1                    # number of jobs / tasks (always 1)
#SBATCH -c 4                    # number of cores (1-4)
#SBATCH -p general              # SLURM partition (always mcbstudent)
#SBATCH --qos=general           # SLURM Quality of service (always mcbstudent)
#SBATCH --mem=8G                # RAM (memory) requested 
#SBATCH -o /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.out
#SBATCH -e /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.err

##########
## LOAD ##
##########

# Record start time
start_time=$(date +%s)  # Get timestamp in seconds

echo "Hostname: $(hostname)"

module load fastqc
module load fastp # automatically detects adaptor sequence, quality trims, polyA tail, requires 50bp

################
## USER INPUT ##
################

# Find adaptor sequence, add bt index
fileDir="$1"      # list of files

# global variables
inPATH="/home/FCAM/rsheih/pxl_rnaseq/data/raw"
outPATH="/home/FCAM/rsheih/pxl_rnaseq/data/processed"
baseDIR=/home/FCAM/rsheih/pxl_rnaseq/data/processed

## If working directory does not exist, create it
mkdir -p $outPATH


for file in ${fileDir}/*.fastq.gz
do
    echo FILE VALUE: ${file}
    echo The number of total reads before pre-processing: 
    zcat ${file} | wc -l | awk '{print $1/4}'

    #####################
    ## FILE PROCESSING ##
    #####################

    ## make prefix for output files
    # prefix=$(echo ${file} | cut -d "." -f 1)
    prefix=$(basename "${file}" .fastq.gz)
    echo running for $prefix

    echo running script on $prefix

    echo running fastqc
    fastqc ${file} -o "${outPATH}"

    echo running fastp on raw data

    # need the fix where looking in folder Skipping '/home/FCAM/rsheih/pxl_rnaseq/data/processed/NZXTV9_3_U2OS_rep_3_trim.fastq.gz' which didn't exist, or couldn't be read

    fastp \
        -i "${file}" \
        -o "${outPATH}/${prefix}_trim.fastq.gz" \
        --trim_poly_x \
        --cut_tail \
        --cut_tail_mean_quality 15 \
        --length_required 50 \
        --detect_adapter_for_pe \
        -h "${outPATH}/${prefix}_fastp.html" \
        -j "${outPATH}/${prefix}_fastp.json"


    echo running fastqc on processed data
    fastqc "${outPATH}/${prefix}_trim.fastq.gz" -o "${outPATH}"

done

date 

# Record end time
end_time=$(date +%s)  # Get timestamp in seconds

# Calculate runtime duration
runtime=$((end_time - start_time))
echo "Pipeline completed successfully."
echo "Total runtime: $((runtime / 60)) minutes and $((runtime % 60)) seconds."

# problem is it is outputting things in the raw folder instead of processed