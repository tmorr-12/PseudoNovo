process CHECKV {
    // https://bitbucket.org/berkeleylab/CheckV/src/master/
    tag "${ID}"
    label "medium"

    container "quay.io/biocontainers/checkv:1.1.1--pyh106432d_1"

    publishDir "${params.outdir}/annotations", pattern: "*_checkv.tsv"

    input:
    tuple val(ID), path(genomad_fna)

    output:
    path("${ID}_checkv_summary.tsv"), emit: checkv_summary

    script:
    """
    mkdir -p checkv_out

    export CHECKVDB=${params.checkv_db}
    checkv end_to_end ${genomad_fna} checkv_out -t ${task.cpus}

    mv checkv_out/quality_summary.tsv ${ID}_checkv.tsv
    """
}