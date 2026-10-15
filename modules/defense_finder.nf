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
    
    script:
    """
    defense-finder run \\
        --models-dir ${models} \\
        -w ${task.cpus} \\
        ${contigs}
    """
}