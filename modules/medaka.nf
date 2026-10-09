process MEDAKA {
    // https://github.com/nanoporetech/medaka
    tag "${ID}"
    label 'large'

    container "quay.io/biocontainers/medaka:2.2.2--py312h3050eb1_0"

    publishDir "${params.outdir}/assemblies", pattern: "*.fasta"

    input:
    tuple val(ID), path(reads), path(fasta)

    output:
    tuple val(ID), path("${ID}_polished.fasta"), emit: polished_ch

    script:
    """
    mkdir medaka_out
    medaka_consensus \\
        -i ${reads[0]} \\
        -d ${fasta} \\
        -o medaka_out \\
        -t ${task.cpus}
    mv medaka_out/consensus.fasta ${ID}_polished.fasta
    """
}