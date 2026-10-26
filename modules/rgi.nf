process RGI {
    // https://github.com/arpcard/rgi
    tag "${ID}"
    label "medium"

    container "quay.io/biocontainers/rgi:6.0.8--pyh05cac1d_0"

    publishDir "${params.outdir}/02-ANNOTATIONS/rgi"

    input:
    tuple val(ID), path(contigs)
    path card_db

    output:
    path("${ID}.txt"), emit: rgi_out
    tuple val('rgi'), eval("rgi main --version"), topic: versions

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

    stub:
    """
    touch ${ID}.txt
    """
}