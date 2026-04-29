#! /bin/sh

#SBATCH --job-name=1_get_files.sh     # name for job
#SBATCH -N 1                    # number of nodes (always 1)
#SBATCH -n 1                    # number of jobs / tasks (always 1)
#SBATCH -c 1                    # number of cores (1-4)
#SBATCH -p general              # SLURM partition 
#SBATCH --qos=general           # SLURM Quality of service 
#SBATCH --mem=8G                # RAM (memory) requested 
#SBATCH -o /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.out
#SBATCH -e /home/FCAM/rsheih/pxl_rnaseq/slurm/%x_%j.err


# Record start time
start_time=$(date +%s)  # Get timestamp in seconds


echo unzipping files 

outDIR=/home/FCAM/rsheih/pxl_rnaseq/data/raw

unzip /home/FCAM/rsheih/pxl_rnaseq/data/raw/NZXTV9_fastq.zip -d $outDIR

for file in "$outDIR"/* 
do
    echo "File saved at: $file"
    wc -l $file 
done

date 

# Record end time
end_time=$(date +%s)  # Get timestamp in seconds

# Calculate runtime duration
runtime=$((end_time - start_time))
echo "Pipeline completed successfully."
echo "Total runtime: $((runtime / 60)) minutes and $((runtime % 60)) seconds."