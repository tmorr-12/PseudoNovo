process PUBLISH_ASSEMBLY {
    tag "${ID}"
    label 'minimal'

    publishDir "${params.outdir}/assemblies"

    input:
    tuple val(ID), path(fasta)

    output:
    path(fasta)

    script:
    """
    echo "${ID} passed assembly QC"
    """
}