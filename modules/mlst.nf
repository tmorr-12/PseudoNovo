process MLST {
    // https://github.com/tseemann/mlst
    tag "${ID}"
    label 'minimal'

    container "quay.io/biocontainers/mlst:2.35.0--hdfd78af_0"

    publishDir "${params.outdir}/00-INTERMEDIATES/mlst", pattern: "*_mlst.tsv"

    input:
    tuple val(ID), path(contigs)

    output:
    tuple val(ID), path("${ID}_mlst.tsv"), emit: mlst_out

    script:
    """
    mlst --full ${contigs} > ${ID}_mlst.tsv
    """
}