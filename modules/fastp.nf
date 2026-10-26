process FASTP {
    // https://github.com/opengene/fastp
    tag "${ID}"
    label 'medium'

    container "quay.io/biocontainers/fastp:1.3.3--h43da1c4_0"

    publishDir "${params.outdir}/00-INTERMEDIATES/fastp", pattern: "*.json"
    publishDir "${params.outdir}/00-INTERMEDIATES/fastp/failed_reads", pattern: "*_failed.fastq"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path("${ID}_{1,2}_fastp.fastq"), val(size), emit: fastp_out_ch
    tuple val(ID), path("${ID}.json"), emit: json
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
        --json ${ID}.json \
        -j ${ID}.json
    """

    stub:
    """
    touch ${ID}_{1,2}_fastp.fastq
    touch ${ID}.json
    touch ${ID}_failed.fastq
    """
}
