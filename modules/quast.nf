process QUAST {
    // https://github.com/ablab/quast
    tag "${ID}"
    label 'minimal'

    container 'quay.io/biocontainers/quast:5.3.0--py39pl5321heaaa4ec_0'

    publishDir "${params.outdir}/00-INTERMEDIATES/quast", pattern: "*_quast_report.tsv"

    input:
    tuple val(ID), path(fasta)

    output:
    tuple val(ID), path("${ID}_quast_report.tsv"), emit: quast_out
    tuple val('quast'), eval('quast.py --version | grep "QUAST" | sed \'s/^.*QUAST v//; s/ .*\$//\''), topic: versions
    path "${ID}_quast", topic: multi_qc

    script:
    def quast_report = "${ID}_quast_report.tsv"
    """
    quast.py ${fasta} -o ${ID}_quast --no-html --no-plots
    cp ${ID}_quast/transposed_report.tsv ${quast_report}
    """

    stub:
    """
    touch ${ID}_quast_report.tsv
    mkdir ${ID}_quast
    touch ${ID}_quast/${ID}_report_multiqc.tsv
    """
}
