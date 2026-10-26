process FASTQC {
    tag "${ID}"
    label 'small'

    container "quay.io/biocontainers/fastqc:0.13.0--hdfd78af_0"

    publishDir "${params.outdir}/00-INTERMEDIATES/fastqc", pattern: "*_summary.txt"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path("${ID}_R1_summary.txt"), emit: r1_summary
    tuple val(ID), path("${ID}_R2_summary.txt"), emit: r2_summary
    tuple val('fastqc'), eval('fastqc --version | sed "/FastQC v/!d; s/.*v//"'), topic: versions

    script:
    def R1="${reads[0]}"
    def R2="${reads[1]}"
    """
    fastqc ${R1} ${R2} --threads ${task.cpus}

    unzip ${ID}_R1_fastqc.zip 1>&2
    unzip ${ID}_R2_fastqc.zip 1>&2

    mv ${ID}_R1_fastqc/summary.txt ${ID}_R1_summary.txt
    mv ${ID}_R2_fastqc/summary.txt ${ID}_R2_summary.txt
    """

    stub:
    """
    touch ${ID}_R1_summary.txt
    touch ${ID}_R2_summary.txt
    """
}