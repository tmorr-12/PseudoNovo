process AUTOCYCLER {
    // https://github.com/rrwick/Autocycler
    tag "${ID}"
    label "huge"

    publishDir "${params.outdir}/${ID}"

    container "ghcr.io/tmorr-12/autocycler:0.7.0_v4"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path("${ID}_consensus.fasta"), emit: fasta_ch
    tuple val(ID), path("${ID}_consensus.yaml"), emit: yaml_ch

    script:
    def command = "${projectDir}/bin/run_autocycler.sh"
    def genome_size = size ?: params.target_genome_size
    """
    ${command} \
        ${reads[0]} \
        ${genome_size} \
        ${params.autocycler_subsets} \
        ${task.cpus}

    mv autocycler_out/consensus_assembly.fasta ${ID}_consensus.fasta
    mv autocycler_out/consensus_assembly.yaml ${ID}_consensus.yaml
    """
}