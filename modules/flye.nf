process FLYE {
    // https://github.com/mikolmogorov/Flye
    tag "${ID}"
    label "large"

    container "quay.io/biocontainers/flye:2.9.6--py313h7fbb527_1"

    publishDir "${params.outdir}/00-INTERMEDIATES/flye"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path(reads), path("${ID}_contigs.fa"), emit: fasta_ch
    tuple val(ID), path("${ID}_assembly_info.txt"), emit: flye_info_ch
    tuple val('flye'), eval('flye --version'), topic: versions

    script:
    def platform = params.long_read_platform == "ont" ? "--nano-hq" : "--pacbio-hifi"
    def long_fastq = reads[0]
    def genome_size = size ?: params.target_genome_size
    """
    flye \\
        ${platform} \\
        ${long_fastq} \\
        -g ${genome_size} \\
        -o . \\
        -t ${task.cpus}

    mv assembly.fasta ${ID}_contigs.fa
    mv assembly_info.txt ${ID}_assembly_info.txt
    """

    stub:
    """
    touch ${ID}_contigs.fa
    touch ${ID}_assembly_info.txt
    """
}