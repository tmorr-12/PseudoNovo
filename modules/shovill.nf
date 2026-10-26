process SHOVILL {
    // https://github.com/tseemann/shovill
    tag "${ID}"
    label 'large'

    container "quay.io/biocontainers/shovill:1.4.2--hdfd78af_1"

    publishDir "${params.outdir}/00-INTERMEDIATES/shovill"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path("${ID}_contigs.fa"), emit: fasta_ch
    tuple val("shovill"), eval("shovill --version 2>&1 | cut -d ' ' -f2"), topic: versions

    script:
    def genome_size = size ?: params.target_genome_size
    """
    shovill \\
        --R1 ${reads[0]} \\
        --R2 ${reads[1]} \\
        --cpus ${task.cpus} \\
        --ram ${task.memory.toGiga()} \\
        --outdir shovill_out \\
        --minlen ${params.min_contig_length} \\
        --gsize ${genome_size}

    mv shovill_out/contigs.fa ${ID}_contigs.fa
    """

    stub:
    """
    touch ${ID}_contigs.fa
    """
}