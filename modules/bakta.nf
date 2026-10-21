process BAKTA {
    // https://github.com/oschwengers/bakta
    tag "${ID}"
    label 'mega'

    container "quay.io/biocontainers/bakta:1.12.1--pyhdfd78af_0"

    publishDir "${params.outdir}/02-ANNOTATIONS/bakta"

    input:
    tuple val(ID), path(contigs)
    path bakta_db

    output:
    path("${ID}.gff3"), emit: bakta_out

    script:
    """
    bakta ${contigs} --db ${bakta_db} --output annotation/ --prefix ${ID} --threads ${task.cpus}
    mv annotation/${ID}*.gff3 ${ID}.gff3
    """
}