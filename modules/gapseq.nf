process GAPSEQ {
    // https://github.com/jotech/gapseq
    tag "${ID}"
    label "large"

    container "quay.io/biocontainers/gapseq:2.1.0--hdfd78af_0"

    publishDir "${params.outdir}/02-ANNOTATIONS/gapseq"

    input:
    tuple val(ID), path(contigs)
    path(gapseq_db)

    output:
    tuple val(ID), path("*-all-Pathways.tbl"), emit: gapseq_pathways
    tuple val(ID), path("*.RDS"), emit: gapseq_model
    tuple val('gapseq'), eval('gapseq -v 2>&1 | grep -oP "\\d+\\.\\d+\\.\\d+"'), topic: versions

    script:
    """
    gapseq \\
        doall \\
        -t Bacteria \\
        -K ${task.cpus} \\
        -D ${gapseq_db} \\
        ${contigs}
    """

    stub:
    """
    touch ${ID}_contigs-all-Pathways.tbl
    touch ${ID}_contigs.RDS
    """
}

process GAPSEQ_DB_DOWNLOAD {
    // https://github.com/jotech/gapseq
    tag "gapseq_seqDB"

    container "quay.io/biocontainers/gapseq:2.1.0--hdfd78af_0"

    storeDir "${params.outdir}/databases"

    output:
    path("gapseq_seqDB"), emit: gapseq_db

    script:
    """
    mkdir gapseq_seqDB

    gapseq \\
        update-sequences \\
        -t Bacteria \\
        -D gapseq_seqDB
    """

    stub:
    """
    mkdir gapseq_seqDB
    touch gapseq_seqDB/seq
    """
}
