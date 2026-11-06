#!/usr/bin/env bash

set -euo pipefail

SUBSAMPLED_DIR=$1
GENOME_SIZE=$2
N_SUBSETS=$3
THREADS=$4

eval "$(micromamba shell hook --shell bash)"

for assembler in flye miniasm necat nextdenovo raven; do
    for i in `eval echo {01..$N_SUBSETS}`; do
        micromamba activate ${assembler}
        autocycler helper \
            ${assembler} \
            --reads ${SUBSAMPLED_DIR}/sample_"$i".fastq \
            --out_prefix assemblies/"$assembler"_"$i" \
            --threads ${THREADS} \
            --genome_size ${GENOME_SIZE}
        micromamba deactivate
    done
done
