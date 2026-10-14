process COLLECT_FASTQ_REPORTS {
    tag "${ID}"
    label 'minimal'

    container 'quay.io/biocontainers/pandas:2.2.1'

    input:
    tuple val(ID), path(reads), val(size), path(fastqc_r1_summary), path(fastqc_r2_summary), path(fastp_json), path(sylph_profile_tsv), path(nanoplot_out)

    output:
    tuple val(ID), path(reads), val(size), stdout, emit: qc_status
    path("${ID}_*_fq_report.tsv"), emit: report

    script:
    def n = reads.size()
    def mode = (n == 2) ? "short" : "long"
    def command="${projectDir}/bin/collect_fq_reports.sh"

    def args = [
        "--id ${ID}",
        "--mode ${mode}",
        "--collect_fq_reports ${projectDir}/bin/collect_fq_reports.py",
        "--sylph_profile_tsv ${sylph_profile_tsv}",
        "--min_depth ${params.min_depth}",
        "--lower_assembly_length ${params.lower_assembly_length}"
    ]
    if (mode == "short") {
        args += [
            "--pass_fail_fastqc ${projectDir}/bin/pass_fail_fastqc.py",
            "--pass_fail_fastp ${projectDir}/bin/pass_fail_fastp.py",
            "--fastqc_r1_summary ${fastqc_r1_summary}",
            "--fastqc_r2_summary ${fastqc_r2_summary}",
            "--fastqc_pass_criteria ${params.fastqc_pass_criteria}",
            "--fastp_json ${fastp_json}"
        ]
    } else {
        args += [
            "--pass_fail_nanoplot ${projectDir}/bin/pass_fail_nanoplot.py",
            "--nanoplot_out ${nanoplot_out}"
        ]
    }
    """
    ${command} ${args.join(' ')}
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
}

process MERGE_REPORTS{
    label 'minimal'

    container 'quay.io/biocontainers/pandas:2.2.1'

    publishDir "${params.outdir}"

    input:
    path reports
    val name

    output:
    path("*.tsv")

    script:
    def command="${projectDir}/bin/merge_reports.py"
    """
    ${command} --reports ${reports} --name ${name}
    """
}