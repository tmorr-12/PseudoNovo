process FASTP {
    // https://github.com/opengene/fastp
    tag "${ID}"
    label 'medium'

    container "quay.io/biocontainers/fastp:1.3.3--h43da1c4_0"

    publishDir "${params.outdir}/fastp", pattern: "${ID}.html"
    publishDir "${params.outdir}/fastp/failed_reads", pattern: "${ID}_failed.fastq"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path("${ID}_{1,2}_fastp.fastq"), val(size), path("${ID}.json"), emit: fastp
    path("${ID}.html"), emit: html
    path("${ID}_failed.fastq"), emit: failed_reads

    script:
    def R1="${reads[0]}"
    def R2="${reads[1]}"
    def out1="${ID}_1_fastp.fastq"
    def out2="${ID}_2_fastp.fastq"
    """
    fastp \
        --in1 ${R1} \
        --in2 ${R2} \
        --out1 ${out1} \
        --out2 ${out2} \
        --failed_out ${ID}_failed.fastq \
        --html ${ID}.html \
        -j ${ID}.json
    """
}

process FILTER_FASTP {
    // https://pmc.ncbi.nlm.nih.gov/articles/PMC3139241/
    // Total base count >= minimum sequence depth * lower assembly length limit
    // Minimum sequence depth = 30x
    // Lower assembly length limit = 5.5Mbp
    // Total base count = 165Mbp
    label 'small'

    input:
    tuple val(ID), path(reads), val(size), path(fastp_json)

    output:
    tuple val(ID), path(reads), val(size), stdout, emit: fastp_out

    script:
    def command="${projectDir}/bin/pass_fail_fastp.py"
    """
    ${command} ${ID} ${fastp_json} ${params.min_depth} ${params.lower_assembly_length}
    """
}