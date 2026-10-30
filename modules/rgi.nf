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

process CARD_DB_DOWNLOAD {
    // https://github.com/arpcard/rgi/blob/master/docs/rgi_load.rst
    tag "CARD"

    storeDir "${params.outdir}/databases"

    output:
    path("card/*"), emit: card_db

    script:
    """
    wget https://card.mcmaster.ca/download/0/broadstreet-v4.0.2.tar.bz2
    tar -xvf broadstreet-v4.0.2.tar.bz2 
    rm broadstreet-v4.0.2.tar.bz2 
    mkdir card
    mv *.* card
    """

    stub:
    """
    mkdir card
    touch card/card.json
    """
}