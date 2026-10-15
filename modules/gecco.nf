process GECCO {
    // https://github.com/zellerlab/GECCO
    tag "${ID}"
    label "small"

    container "quay.io/biocontainers/gecco:0.11.0--pyhdfd78af_0"

    publishDir "${params.outdir}/02-ANNOTATIONS/gecco"

    input:
    tuple val(ID), path(contigs)

    output:
    path ("${ID}*.genes.tsv")

    script:
    """
    gecco run \\
        --genome ${contigs} \\
        -o . \\
        --jobs ${task.cpus}
    """
}