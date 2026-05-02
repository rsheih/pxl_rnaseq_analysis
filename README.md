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

## Notes
Raw data not included.

## Acknowledgments

Thank you to Dr. Michael Guertin and Dr. Pedro Miura for providing the initial script framework for this pipeline. Portions of this repository were developed with assistance from ChatGPT (OpenAI) for code suggestions, debugging, and workflow structuring. All final decisions, implementation, and validation were performed by the author. 