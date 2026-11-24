#!/usr/bin/env bash

# hybrid reads require sra-tools (https://github.com/ncbi/sra-tools)
mkdir hybrid_read && cd hybrid_read
prefetch SRR30916324 # Illumina reads
prefetch SRR30916323 # ONT reads
fasterq-dump SRR30916324 # Illumina reads
fasterq-dump SRR30916323 # ONT reads