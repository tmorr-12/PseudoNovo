process COLLECT_FASTQ_REPORTS {
    tag "${ID}"
    label 'minimal'

    container 'quay.io/biocontainers/pandas:2.2.1'

    input:
    tuple val(ID), path(reads), val(size), path(fastqc_r1), path(fastqc_r2), path(sylph_tsv), path(nanoplot_out)

    output:
    tuple val(ID), path(reads), val(size), stdout, emit: qc_status
    path("${ID}_*_fq_report.tsv"), emit: report

    script:
    def n = reads.size()
    def mode = (n == 2) ? "short" : "long"
    def command="${projectDir}/bin/collect_fq_reports.py"
    def fastqc_pass_criteria="${projectDir}/assets/fastqc_pass_criteria.json"
    def sample_fq = "${reads[0]}"

    def args = [
        "--id ${ID}",
        "--mode ${mode}",
        "--min_depth ${params.min_depth}",
        "--lower_assembly_length ${params.lower_assembly_length}",
        "--sylph_profile ${sylph_tsv}"
    ]
    if (mode == "short") {
        args += [
            "--fastqc_r1 ${fastqc_r1}",
            "--fastqc_r2 ${fastqc_r2}",
            "--pass_criteria_json ${fastqc_pass_criteria}",
            "--sample_fq ${sample_fq}"
        ]
    } else {
        args += [
            "--nanoplot_out ${nanoplot_out}"
        ]
    }
    """
    ${command} ${args.join(' ')}
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