process COLLECT_REPORTS {
    tag "${ID}"
    label 'small'

    container 'quay.io/biocontainers/pandas:2.2.1'

    input:
    tuple val(ID), path(fasta), path(reports, stageAs: "reports/*")

    output:
    tuple val(ID), path(fasta), stdout, emit: contigs
    path("${ID}_report.tsv"), emit: report

    script:
    def command="${projectDir}/bin/collect_report.py"
    def config="${projectDir}/assets/report_keep_columns.json"
    """
    ${command} \
        --id ${ID} \
        --reports reports/* \
        --config ${config} \
        --target_size ${params.target_genome_size} \
        --completeness ${params.completeness} \
        --contamination ${params.contamination} \
        --gc ${params.target_gc_content}
    """
}

process MERGE_REPORTS{
    label 'small'

    container 'quay.io/biocontainers/pandas:2.2.1'

    publishDir "${params.outdir}"

    input:
    path reports

    output:
    path("assembly_report.tsv")

    script:
    def command="${projectDir}/bin/merge_reports.py"
    """
    ${command} --reports ${reports}
    """
}