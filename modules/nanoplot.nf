process NANOPLOT {
    // https://github.com/wdecoster/nanoplot
    tag "${ID}"
    label 'small'

    container "quay.io/biocontainers/nanoplot:1.47.1--pyhdfd78af_0"

    input:
    tuple val(ID), path(reads), val(size)
    val(stage)

    output:
    tuple val(ID), path("*.txt"), emit: nanostats

    script:
    def long_fastq="${reads[0]}"
    """
    NanoPlot --fastq ${long_fastq} --N50 -p ${ID}_${stage} --threads ${task.cpus}
    """
}

process COMPARE_NANOPLOT {
    tag "${ID}"
    label 'minimal'

    publishDir "${params.outdir}/nanoplot"

    input:
    tuple val(ID), path(pre_report), path(post_report)

    output:
    path("${ID}_NanoStats_Summary.tsv"), emit: nanostats

    script:
    def command = "${projectDir}/bin/compare_nanoplot.py"
    """
    ${command} ${ID} ${pre_report} ${post_report}
    """
}