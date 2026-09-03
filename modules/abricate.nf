process ABRICATE {
    // https://github.com/tseemann/abricate
    tag "${ID}"
    label 'medium'

    container "quay.io/biocontainers/abricate:1.4.0--h05cac1d_0"

    publishDir "${params.outdir}/${ID}/abricate"

    input:
    tuple val(ID), path(contigs)

    output:
    path("${ID}_*.tsv"), emit: abricate_out

    script:
    """
    abricate --db plasmidfinder ${contigs} > ${ID}_plasmidfinder.tsv
    abricate --db vfdb ${contigs} > ${ID}_vfdb.tsv
    """
}