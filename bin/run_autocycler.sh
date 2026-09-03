#!/usr/bin/env bash

set -euo pipefail

# adapted from https://github.com/rrwick/Autocycler/blob/main/pipelines/autocycler_wrapper_by_iskold/autocycler_wrapper.sh
# commit SHA: 8abf4939f3c8eab3c7c32947f874574005f04633

LONG_FASTQ=$1
GENOME_SIZE=$2
N_SUBSETS=$3
THREADS=$4

eval "$(micromamba shell hook --shell bash)"

# Step 1: subsample the long-read set into multiple files
autocycler subsample \
    --count ${N_SUBSETS} \
    --reads ${LONG_FASTQ} \
    --out_dir subsampled_reads \
    --genome_size ${GENOME_SIZE}

# Step 2: assemble each subsampled file
mkdir -p assemblies
for assembler in flye metamdbg miniasm necat nextdenovo raven; do
    for i in `eval echo {01..$N_SUBSETS}`; do
        micromamba activate ${assembler}
        autocycler helper \
            ${assembler} \
            --reads subsampled_reads/sample_"$i".fastq \
            --out_prefix assemblies/"$assembler"_"$i" \
            --threads ${THREADS} \
            --genome_size ${GENOME_SIZE}
        micromamba deactivate
    done
done

# Optional step: remove the subsampled reads to save space
rm subsampled_reads/*.fastq

# Step 3: compress the input assemblies into a unitig graph
autocycler compress -i assemblies -a autocycler_out

# Step 4: cluster the input contigs into putative genomic sequences
autocycler cluster -a autocycler_out

# Steps 5 and 6: trim and resolve each QC-pass cluster
for c in autocycler_out/clustering/qc_pass/cluster_*; do
    autocycler trim -c "$c"
    autocycler resolve -c "$c"
done

# Step 7: combine resolved clusters into a final assembly
autocycler combine -a autocycler_out -i autocycler_out/clustering/qc_pass/cluster_*/5_final.gfa