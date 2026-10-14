process MULTIQC {
    // https://seqera.io/multiqc/
    label 'medium'

    container "quay.io/biocontainers/multiqc:1.35--pyhdfd78af_1"

    publishDir "${params.outdir}"

    input:
    tuple val(filename), path "*"

    output:
    path "*multiqc_report.html", emit: report

    script:
    """
    multiqc --force . -n ${filename}
    """
}