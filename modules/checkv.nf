process CHECKV {
    // https://bitbucket.org/berkeleylab/CheckV/src/master/
    tag "${ID}"
    label "medium"

    container "quay.io/biocontainers/checkv:1.1.1--pyh106432d_1"

    publishDir "${params.outdir}/02-ANNOTATIONS/checkv", pattern: "*_checkv_summary.tsv"

    input:
    tuple val(ID), path(genomad_fna)
    path(checkv_db)

    output:
    path("${ID}_checkv_summary.tsv"), emit: checkv_summary
    tuple val("checkv"), eval("checkv --version | cut -d ' ' -f 3"), topic: versions

    script:
    """
    mkdir -p checkv_out

    export CHECKVDB=${checkv_db}
    checkv end_to_end ${genomad_fna} checkv_out -t ${task.cpus}

    mv checkv_out/quality_summary.tsv ${ID}_checkv_summary.tsv
    """

    stub:
    """
    touch ${ID}_checkv_summary.tsv
    """
}

process CHECKV_DB_DOWNLOAD {
    // https://bitbucket.org/berkeleylab/CheckV/src/master/
    tag "checkv-db"

    container "quay.io/biocontainers/checkv:1.1.1--pyh106432d_1"

    storeDir "${params.outdir}/databases"

    output:
    path("checkv-db-v1.5"), emit: checkv_db

    script:
    """
    checkv download_database ./
    """

    stub:
    """
    mkdir checkv-db-v1.5
    touch checkv-db-v1.5/checkv.db 
    """
}