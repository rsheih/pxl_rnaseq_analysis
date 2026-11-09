#!/usr/bin/env bash
#SBATCH --job-name=pxl_rnaseq_master
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=2-00:00:00
#SBATCH --output=pxl_master_%j.out
#SBATCH --error=pxl_master_%j.err

# Run from anywhere: sbatch scripts/master_rnaseq.sbatch
# This is a self-contained, restartable equivalent of repository stages 1–6.
# It assumes single-end gzipped FASTQ, as the existing scripts do.
# Override PROJECT_DIR, GTF, FASTA, TRANSCRIPTS, or RAW_ZIP via --export=ALL,KEY=value.

set -Eeuo pipefail
shopt -s nullglob

PROJECT_DIR="${PROJECT_DIR:-/home/FCAM/rsheih/pxl_rnaseq}"
RAW_DIR="${RAW_DIR:-$PROJECT_DIR/data/raw}"
TRIM_DIR="${TRIM_DIR:-$PROJECT_DIR/data/processed}"
REF_DIR="${REF_DIR:-$PROJECT_DIR/genomes}"
FASTA="${FASTA:-$REF_DIR/GRCh38.primary_assembly.genome.fa}"
GTF="${GTF:-$REF_DIR/gencode.v49.annotation.gtf}"
TRANSCRIPTS="${TRANSCRIPTS:-$REF_DIR/gencode.v49.transcripts.fa}"
STAR_INDEX="${STAR_INDEX:-$REF_DIR/star_index_v49}"
SALMON_INDEX="${SALMON_INDEX:-$REF_DIR/salmon_index_v49}"
STAR_DIR="${STAR_DIR:-$PROJECT_DIR/star_out}"
SORTED_DIR="${SORTED_DIR:-$STAR_DIR/bam_sorted}"
SALMON_DIR="${SALMON_DIR:-$PROJECT_DIR/salmon_quant}"
BW_DIR="${BW_DIR:-$PROJECT_DIR/out_bw_2}"
STATE_DIR="${STATE_DIR:-$PROJECT_DIR/checkpoints}"
RAW_ZIP="${RAW_ZIP:-$RAW_DIR/NZXTV9_fastq.zip}"
THREADS="${SLURM_CPUS_PER_TASK:-8}"

mkdir -p "$RAW_DIR" "$TRIM_DIR" "$STAR_DIR" "$SORTED_DIR" "$SALMON_DIR" "$BW_DIR" "$STATE_DIR"
log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }
trap 'log "FAILED at line $LINENO (exit $?) — rerun sbatch to resume" >&2' ERR

# A done marker is trusted only when its outputs are also nonempty/valid.
done_with_files() {
  local marker="$1"; shift
  [[ -f "$marker" ]] || return 1
  local f
  for f in "$@"; do [[ -s "$f" ]] || return 1; done
}
mark_done() { touch "$1"; }
load_module() { module load "$1"; }

log "Project: $PROJECT_DIR; threads: $THREADS"
[[ -s "$FASTA" ]] || die "Missing genome FASTA: $FASTA"
[[ -s "$GTF" ]] || die "Missing v49 GTF: $GTF"
[[ -s "$TRANSCRIPTS" ]] || die "Missing transcript FASTA: $TRANSCRIPTS"

# Stage 1: safely skip extraction if fastq.gz files already exist.
raw_fastqs=("$RAW_DIR"/*.fastq.gz)
if (( ${#raw_fastqs[@]} == 0 )); then
  [[ -s "$RAW_ZIP" ]] || die "No FASTQs in $RAW_DIR and no ZIP at $RAW_ZIP"
  log "Stage 1: extracting $RAW_ZIP"
  unzip -n "$RAW_ZIP" -d "$RAW_DIR"
  # ZIP may contain nested folders; find recursively rather than guessing layout.
  mapfile -d '' raw_fastqs < <(find "$RAW_DIR" -type f -name '*.fastq.gz' -print0 | sort -z)
fi
(( ${#raw_fastqs[@]} > 0 )) || die "No .fastq.gz files found after extraction"

# Reject paired-end files rather than silently treating mates as independent samples.
for f in "${raw_fastqs[@]}"; do
  case "$(basename "$f")" in
    *_R1*.fastq.gz|*_R2*.fastq.gz|*_1.fastq.gz|*_2.fastq.gz)
      die "Paired-end-looking FASTQ: $f. This driver is single-end only; adapt fastp/STAR/Salmon to mates first." ;;
  esac
done

load_module fastqc
load_module fastp
load_module salmon/1.9.0
load_module STAR/2.7.11a
load_module samtools
load_module deeptools/3.5.0

# Stages 2–6 are checkpointed per sample. A failed sample is retried on rerun.
for raw in "${raw_fastqs[@]}"; do
  sample="$(basename "$raw" .fastq.gz)"
  trim="$TRIM_DIR/${sample}_trim.fastq.gz"
  qc_marker="$STATE_DIR/${sample}.fastp.done"
  if ! done_with_files "$qc_marker" "$trim" "$TRIM_DIR/${sample}_fastp.json"; then
    log "Stage 2: FastQC/fastp $sample"
    fastqc --threads "$THREADS" -o "$TRIM_DIR" "$raw"
    fastp -w "$THREADS" -i "$raw" -o "${trim%.fastq.gz}.partial.fastq.gz" \
      --trim_poly_x --cut_tail --cut_tail_mean_quality 15 --length_required 50 \
      -h "$TRIM_DIR/${sample}_fastp.html" -j "$TRIM_DIR/${sample}_fastp.json"
    mv "${trim%.fastq.gz}.partial.fastq.gz" "$trim"
    fastqc --threads "$THREADS" -o "$TRIM_DIR" "$trim"
    mark_done "$qc_marker"
  else log "Skip stage 2: $sample"; fi
done

# Indexes are rebuilt when absent. Use fresh v49 directories, not old v44 indexes.
if [[ ! -s "$SALMON_INDEX/hash.bin" || ! -s "$SALMON_INDEX/versionInfo.json" ]]; then
  log "Stage 3a: build Salmon v49 index"
  mkdir -p "$SALMON_INDEX"
  salmon index -t "$TRANSCRIPTS" -i "$SALMON_INDEX" -k 31 -p "$THREADS" --gencode
fi
if [[ ! -s "$STAR_INDEX/Genome" || ! -s "$STAR_INDEX/SA" ]]; then
  log "Stage 3b: build STAR v49 index"
  mkdir -p "$STAR_INDEX"
  STAR --runThreadN "$THREADS" --runMode genomeGenerate \
    --genomeDir "$STAR_INDEX" --genomeFastaFiles "$FASTA" --sjdbGTFfile "$GTF"
fi

for raw in "${raw_fastqs[@]}"; do
  sample="$(basename "$raw" .fastq.gz)"
  trim="$TRIM_DIR/${sample}_trim.fastq.gz"
  quant="$SALMON_DIR/$sample/quant.sf"
  qmarker="$STATE_DIR/${sample}.salmon.done"
  if ! done_with_files "$qmarker" "$quant"; then
    log "Stage 4a: Salmon $sample"
    salmon quant -i "$SALMON_INDEX" -l A -r "$trim" -p "$THREADS" \
      --validateMappings -o "$SALMON_DIR/$sample"
    [[ -s "$quant" ]] || die "Missing Salmon result $quant"
    mark_done "$qmarker"
  else log "Skip Salmon: $sample"; fi

  bam="$STAR_DIR/$sample.bam"
  smarker="$STATE_DIR/${sample}.star.done"
  if ! done_with_files "$smarker" "$bam"; then
    log "Stage 4b: STAR $sample"
    STAR --runThreadN "$THREADS" --genomeDir "$STAR_INDEX" \
      --readFilesIn "$trim" --readFilesCommand zcat \
      --outFileNamePrefix "$STAR_DIR/${sample}_" \
      --outSAMtype BAM SortedByCoordinate --outBAMsortingThreadN "$THREADS" \
      --outFilterType BySJout --outFilterMultimapNmax 20 \
      --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 \
      --outFilterMismatchNmax 999 --outFilterMismatchNoverReadLmax 0.04 \
      --alignIntronMin 20 --alignIntronMax 300000 --alignMatesGapMax 300000
    candidate="$STAR_DIR/${sample}_Aligned.sortedByCoord.out.bam"
    [[ -s "$candidate" ]] || die "Missing STAR BAM: $candidate"
    mv "$candidate" "$bam"
    samtools quickcheck "$bam" || die "BAM validation failed: $bam"
    mark_done "$smarker"
  else log "Skip STAR: $sample"; fi

  # STAR already coordinate-sorts. Avoid a redundant sort pass; create a
  # consistently located BAM and index for the coverage stage.
  sorted="$SORTED_DIR/${sample}_sorted.bam"
  bmarker="$STATE_DIR/${sample}.sorted.done"
  if ! done_with_files "$bmarker" "$sorted" "${sorted}.bai"; then
    log "Stage 5: validate/index sorted BAM $sample"
    samtools quickcheck "$bam" || die "Bad BAM $bam"
    # Atomic temporary link avoids copying a potentially large BAM.
    ln -sfn "$bam" "${sorted}.tmp-link"
    mv -Tf "${sorted}.tmp-link" "$sorted"
    samtools index -@ "$THREADS" "$sorted"
    mark_done "$bmarker"
  else log "Skip stage 5: $sample"; fi

  bw="$BW_DIR/${sample}.bw"
  wmarker="$STATE_DIR/${sample}.bw.done"
  if ! done_with_files "$wmarker" "$bw"; then
    log "Stage 6: CPM-normalized BigWig $sample"
    bamCoverage -p "$THREADS" --normalizeUsing CPM \
      -b "$sorted" -o "${bw}.partial.bw"
    [[ -s "${bw}.partial.bw" ]] || die "Missing BigWig for $sample"
    mv "${bw}.partial.bw" "$bw"
    mark_done "$wmarker"
  else log "Skip stage 6: $sample"; fi
done

log "SUCCESS: all ${#raw_fastqs[@]} single-end samples processed through BigWig"
