process COLLECT_FASTQ_REPORTS {
    tag "${ID}"
    label 'minimal'

    container 'quay.io/biocontainers/pandas:2.2.1'

    input:
    tuple val(ID), path(reads), val(size), path(fastqc_r1_summary), path(fastqc_r2_summary), val(depth), path(sylph_profile_tsv), path(nanoplot_out)

    output:
    tuple val(ID), path(reads), val(size), stdout, emit: qc_status
    path("${ID}_*_fq_report.tsv"), emit: report

    script:
    def n = reads.size()
    def mode = (n == 2) ? "short" : "long"
    def command="${projectDir}/bin/collect_fq_reports.py"
    def pass_fail_fastqc="${projectDir}/bin/pass_fail_fastqc.py"
    def fastqc_pass_criteria="${projectDir}/assets/fastqc_pass_criteria.json"
    def pass_fail_nanoplot="${projectDir}/bin/pass_fail_nanoplot.py"
    """
    fastqc_r1_status="na"
    fastqc_r2_status="na"
    sylph_status="na"
    nanoplot_status="na"

    sylph_status=\$(sed -n '2p' "${sylph_profile_tsv}" | awk -F'\t' '$4 > 98 {found=1} END {print (found ? "PASS" : "FAIL")}')

    if [[ ${mode} == "short" ]]; then
        fastqc_r1_status=\$(${pass_fail_fastqc} --summary_file ${fastqc_r1_summary} --pass_criteria_json ${fastqc_pass_criteria})
        fastqc_r2_status=\$(${pass_fail_fastqc} --summary_file ${fastqc_r2_summary} --pass_criteria_json ${fastqc_pass_criteria})
    else
        nanoplot_status=\$(${pass_fail_nanoplot} ${nanoplot_out} ${params.min_depth} ${params.lower_assembly_length})
    fi

    ${command} \
        --id ${ID} \
        --mode ${mode} \
        --fastqc_r1 \${fastqc_r1_status} \
        --fastqc_r2 \${fastqc_r2_status} \
        --sylph \${sylph_status} \
        --depth ${depth} \
        --nanoplot \${nanoplot_status}
    """

    stub:
    def mode = (reads.size() == 2) ? "short" : "long"
    """
    touch ${ID}_${params.mode}_fq_report.tsv
    echo PASS
    """
}

process COLLECT_ASSEMBLY_REPORTS {
    tag "${ID}"
    label 'minimal'

    container 'quay.io/biocontainers/pandas:2.2.1'

    input:
    tuple val(ID), path(fasta), path(reports, stageAs: "reports/*")

    output:
    tuple val(ID), path(fasta), stdout, emit: contigs
    path("${ID}_report.tsv"), emit: report

    script:
    def command="${projectDir}/bin/collect_assembly_reports.py"
    def config="${projectDir}/assets/report_keep_columns.json"
    """
    ${command} \
        --id ${ID} \
        --reports reports/* \
        --config ${config} \
        --target_size ${params.target_genome_size} \
        --completeness ${params.completeness} \
        --contamination ${params.contamination} \
        --gc ${params.target_gc_content} \
        --gtdb_classification "${params.gtdb_classification}"
    """

    stub:
    """
    touch ${ID}_report.tsv
    echo PASS
    """
}

process MERGE_REPORTS{
    label 'minimal'

    container 'quay.io/biocontainers/pandas:2.2.1'

    publishDir "${params.outdir}"

    input:
    path reports
    val name

    output:
    path("${name}.tsv")

    script:
    def command="${projectDir}/bin/merge_reports.py"
    """
    ${command} --reports ${reports} --name ${name}
    """

    stub:
    """
    touch ${name}.tsv
    """
}