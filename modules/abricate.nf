process ABRICATE {
    // https://github.com/tseemann/abricate
    tag "${ID}"
    label 'minimal'

    container "quay.io/biocontainers/abricate:1.4.0--h05cac1d_0"

    publishDir "${params.outdir}/02-ANNOTATIONS/abricate"

    input:
    tuple val(ID), path(contigs)

    output:
    path("${ID}_plasmidfinder.tsv"), emit: abricate_out
    

    script:
    """
    abricate --db plasmidfinder ${contigs} > ${ID}_plasmidfinder.tsv
    """

    stub:
    """
    touch ${ID}_plasmidfinder.tsv
    """
}