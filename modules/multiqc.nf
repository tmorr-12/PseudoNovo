process MULTIQC {
    // https://seqera.io/multiqc/
    label 'medium'

    container "quay.io/biocontainers/multiqc:1.15--pyh9f0ad1d_0"

    publishDir "${params.outdir}"

    input:
    path trigger

    output:
    path "*multiqc_report.html", emit: report

    script:
    """
    multiqc --force ${params.outdir}
    """
}