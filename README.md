# RNA-seq Analysis: U2OS WT vs PMLKO

## Overview
Differential expression analysis comparing WT vs PML knockout U2OS cells.

## Pipeline
FastQC → fastp → STAR → IGV
AND 
FastQC → fastp → Salmon → tximport → DESeq2

## Samples
- 3 WT
- 3 KO

## Reference
GRCh38.primary_assembly.genome.fa

## Tools
- fastp v0.24.0
- FastQC v0.12.1
- STAR v2.7.11
- samtools v1.22.1
- edgeR v4.0.16

## Recommended Structure
project
├── data
│   ├── raw
│   └── processed 
├── genomes
│   ├── salmon_index
│   ├── star_index
│   ├── gencode.v44.annotation.gtf
│   ├── gencode.v49.transcripts.fa
│   └── GRCh38.primary_assembly.genome.fa
├── scripts
│   ├── 1_get_files.sh 
│   ├── 2_process.sh
│   ├── 3a_salmon_index.sh
│   ├── 3b_star_index.sh
│   ├── 4a_run_salmon.sh
│   ├── 4b_run_star.sh
│   ├── 5_coordinate_sorting.sh
│   └── 6_bam_to_bw.sh
├── slurm
├── star_out
└── salmon_quant


## Notes
Raw data not included.

## Acknowledgments

Thank you to Dr. Michael Guertin and Dr. Pedro Miura for providing the initial script framework for this pipeline. Portions of this repository were developed with assistance from ChatGPT (OpenAI) for code suggestions, debugging, and workflow structuring. All final decisions, implementation, and validation were performed by the author. 