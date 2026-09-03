process NANOPLOT {
    // https://github.com/wdecoster/nanoplot
    tag "${ID}"
    label 'small'

    container "quay.io/biocontainers/nanoplot:1.47.1--pyhdfd78af_0"

    publishDir "${params.outdir}/nanoplot", pattern: "${ID}_${stage}NanoPlot-report.html"

    input:
    tuple val(ID), path(reads), val(size)
    val(stage)

    output:
    tuple val(ID), path(reads), val(size), path("*.txt"), emit: nanostats
    tuple val(ID), path("*.html"), emit: html

    script:
    def long_fastq="${reads[0]}"
    """
    NanoPlot --fastq ${long_fastq} --N50 -p ${ID}_${stage} --threads ${task.cpus}
    """
}

process FILTER_NANOPLOT {
    tag "${ID}"
    label 'small'

    input:
    tuple val(ID), path(reads), val(size), path(nanostats_txt)

    output:
    tuple val(ID), path(reads), val(size), stdout, emit: nanoplot_out

    script:
    def command = "${projectDir}/bin/pass_fail_nanoplot.py"
    """
    ${command} ${ID} ${nanostats_txt} ${params.min_depth} ${params.lower_assembly_length}
    """
}

process COMPARE_NANOPLOT {
    tag "${ID}"
    label 'small'

    publishDir "${params.outdir}/${ID}"

    input:
    tuple val(ID), path(pre_report), path(post_report)

    output:
    path("${ID}_NanoStats_Summary.tsv")

    script:
    def command = "${projectDir}/bin/compare_nanoplot.py"
    """
    ${command} ${ID} ${pre_report} ${post_report}
    """
}