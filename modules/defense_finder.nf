process DEFENSE_FINDER {
    // https://github.com/mdmparis/defense-finder
    tag "${ID}"
    label "small"

    container "quay.io/biocontainers/defense-finder:3.0.0--pyhdfd78af_0"

    publishDir "${params.outdir}/02-ANNOTATIONS/defense_finder"

    input:
    tuple val(ID), path(contigs)
    path(models)

    output:
    path("${ID}*_defense_finder_genes.tsv"), emit: genes
    tuple val('defense-finder'), eval("defense-finder version | cut -d ' ' -f 4"), topic: versions
    
    script:
    """
    export HOME=\$PWD

    defense-finder run \\
        --models-dir ${models} \\
        -w ${task.cpus} \\
        ${contigs}
    """

    stub:
    """
    touch ${ID}_defense_finder_genes.tsv
    """
}

process DEFENSE_FINDER_MODELS_DOWNLOAD {
    // https://github.com/mdmparis/defense-finder
    tag "defense-finder-models_3.1.0"

    container "quay.io/biocontainers/defense-finder:3.0.0--pyhdfd78af_0"

    storeDir "${params.outdir}/databases"

    output:
    path("defense-finder-models"), emit: defensefinder_models

    script:
    """
    mkdir models
    export HOME=\$PWD/models
    defense-finder update

    mkdir -p defense-finder-models
    mv models/.macsyfinder/models/* defense-finder-models
    """

    stub:
    """
    mkdir -p defense-finder-models
    touch defense-finder-models/defense-finder-models
    touch defense-finder-models/CasFinder
    """
}