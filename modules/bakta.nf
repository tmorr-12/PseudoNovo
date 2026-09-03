process BAKTA {
    // https://github.com/oschwengers/bakta
    tag "${ID}"
    label 'large'

    container "quay.io/biocontainers/bakta:1.12.0--pyhdfd78af_0"

    publishDir "${params.outdir}/${ID}"

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