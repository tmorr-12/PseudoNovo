process RGI {
    // https://github.com/arpcard/rgi
    tag "${ID}"
    label "medium"

    container "quay.io/biocontainers/rgi:6.0.8--pyh05cac1d_0"

    publishDir "${params.outdir}/annotations"

    input:
    tuple val(ID), path(contigs)
    path card_db

    output:
    path("${ID}*"), emit: rgi_out

    script:
    """
    rgi load --card_json card.json --local
    rgi main \\
        --input_sequence ${contigs} \\
        --output_file ${ID} \\
        --input_type contig \\
        --local \\
        --alignment_tool DIAMOND \\
        -n ${task.cpus} \\
        --clean
    """
}