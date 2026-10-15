process HOSTILE {
    // https://github.com/bede/hostile
    tag "${ID}"
    label args.mode == "short" ? "large" : "huge"

    container "quay.io/biocontainers/hostile:2.0.2--pyhdfd78af_0"

    publishDir "${params.outdir}/00-INTERMEDIATES/hostile", pattern: "*.json"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path("${ID}*.clean*"), val(size), emit: cleaned_reads
    path("log.json"), emit: hostile_log

    script:
    def n = reads.size()
    def args = n == 1 ? "--fastq1 ${reads[0]} --aligner minimap2" : "--fastq1 ${reads[0]} --fastq2 ${reads[1]} --aligner bowtie2"
    """
    hostile clean \\
        ${args} \\
        --index human-t2t-hla-argos985 \\
        --threads ${task.cpus} \\
        -o . \\
        --airplane \\
    > log.json
    """
}