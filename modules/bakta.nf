process BAKTA {
    // https://github.com/oschwengers/bakta
    tag "${ID}"
    label 'huge'

    container "quay.io/biocontainers/bakta:1.12.1--pyhdfd78af_0"

    publishDir "${params.outdir}/02-ANNOTATIONS/bakta"

    input:
    tuple val(ID), path(contigs)
    path bakta_db

    output:
    tuple val(ID), path("${ID}.gff3"), emit: bakta_out
    tuple val('bakta'), eval("bakta --version | cut -d ' ' -f 2"), topic: versions
    path "${ID}.txt", topic: multi_qc

    script:
    def locus_tag = params.locus_tag ? "--locus-tag ${params.locus_tag}" : ""
    """
    bakta \\
        ${contigs} \\
        --db ${bakta_db} \\
        --prefix ${ID} \\
        --threads ${task.cpus} \\
        --genus Pseudomonas \\
        --species aeruginosa \\
        ${locus_tag} \\
        --compliant
    """

    stub:
    """
    touch ${ID}.gff3
    touch ${ID}.txt
    """
}

process BAKTA_DB_DOWNLOAD {
    // https://github.com/oschwengers/bakta#database
    tag "db"

    container "quay.io/biocontainers/bakta:1.12.1--pyhdfd78af_0"

    storeDir "${params.outdir}/databases"

    output:
    path("db*"), emit: bakta_db

    script:
    """
    bakta_db download
    """

    stub:
    """
    mkdir db
    touch db/db.db
    """
}