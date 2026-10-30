process MULTIQC {
    // https://github.com/multiqc/multiqc
    label "medium"

    container "quay.io/biocontainers/multiqc:1.35--pyhdfd78af_2"

    publishDir "${params.outdir}"

    input:
    path "*"

    output:
    path "*.html"
    tuple val('multiqc'), eval("multiqc --version 2>&1 | sed 's/^.* //'"), topic: versions

    script:
    """
    multiqc -f -n multiqc_report.html .
    """

    stub:
    """
    touch multiqc_report.html
    """
}