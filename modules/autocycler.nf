process AUTOCYCLER_SUBSAMPLE {
    // https://github.com/rrwick/Autocycler/wiki/Autocycler-subsample
    tag "${ID}"
    label "small"

    container "quay.io/biocontainers/autocycler:0.8.0--h79ce301_0"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path(reads), path("subsampled_reads"), val(size)

    script:
    def genome_size = size ?: params.target_genome_size
    def long_fastq = params.mode == "hybrid" ? reads[2] : reads[0]
    """
    autocycler subsample \\
        --count ${params.autocycler_subsets} \\
        --reads ${long_fastq} \\
        --out_dir subsampled_reads \\
        --genome_size ${genome_size}
    """

    stub:
    """
    mkdir subsampled_reads
    touch subsampled_reads/subsampled.fastq
    """
}

process AUTOCYCLER_ASSEMBLE {
    // https://github.com/rrwick/Autocycler/wiki/Generating-input-assemblies
    tag "${ID}"
    label "huge"

    container "ghcr.io/tmorr-12/autocycler:0.7.0_v4"

    input:
    tuple val(ID), path(reads), path(subsampled_reads), val(size)

    output:
    tuple val(ID), path(reads), path("assemblies")

    script:
    def command = "${projectDir}/bin/autocycler_assembly_wrapper.sh"
    def genome_size = size ?: params.target_genome_size
    """
    mkdir -p assemblies
    ${command} \\
        ${subsampled_reads} \\
        ${genome_size} \\
        ${params.autocycler_subsets} \\
        ${task.cpus}
    """

    stub:
    """
    mkdir assemblies
    touch assemblies/${ID}_1.fasta
    """
}

process AUTOCYCLER_COMPRESS {
    // https://github.com/rrwick/Autocycler/wiki/Autocycler-compress
    tag "${ID}"
    label "medium"

    container "quay.io/biocontainers/autocycler:0.8.0--h79ce301_0"

    input:
    tuple val(ID), path(reads), path(assemblies)

    output:
    tuple val(ID), path(reads), path("autocycler_out")

    script:
    """
    autocycler \\
        compress \\
        -i ${assemblies} \\
        -a autocycler_out \\
        -t ${task.cpus}
    """

    stub:
    """
    mkdir autocycler_out
    touch autocycler_out/consensus_assembly.fasta
    """
}

process AUTOCYCLER_CLUSTER_AND_COMBINE {
    // https://github.com/rrwick/Autocycler/wiki/Fully-automated-assembly
    tag "${ID}"
    label "small"

    container "quay.io/biocontainers/autocycler:0.8.0--h79ce301_0"

    input:
    tuple val(ID), path(reads), path(assemblies)

    output:
    tuple val(ID), path(reads), path("${ID}_consensus.fa"), emit: fasta_ch
    tuple val(ID), path("${ID}_consensus.yaml"), emit: yaml_ch
    tuple val("autocycler"), eval("autocycler --version |  sed 's/^[^ ]* //'"), topic: versions

    script:
    """
    mkdir -p ${ID}_cached
    cp -r ${assemblies}/* ${ID}_cached

    autocycler \\
        cluster \\
        -a ${ID}_cached

    for c in ${ID}_cached/clustering/qc_pass/cluster_*; do
        autocycler trim -c \$c
        autocycler resolve -c \$c
    done

    autocycler \\
        combine \\
        -a ${ID}_cached \\
        -i ${ID}_cached/clustering/qc_pass/cluster_*/5_final.gfa

    mv ${ID}_cached/consensus_assembly.fasta ${ID}_consensus.fa
    mv ${ID}_cached/consensus_assembly.yaml ${ID}_consensus.yaml
    """

    stub:
    """
    touch ${ID}_consensus.fa
    touch ${ID}_consensus.yaml
    """
}
