process GTDBTK {
    // https://github.com/ecogenomics/gtdbtk
    tag "${ID}"
    label "gtdb"

    container "quay.io/biocontainers/gtdbtk:2.7.2--pyhdfd78af_1"

    publishDir "${params.outdir}/00-INTERMEDIATES/gtdbtk"

    input:
    tuple val(ID), path(contigs, stageAs: "fastas/*")
    path(gtdb)

    output:
    tuple val(ID), path("${ID}_gtdbtk.tsv"), emit: gtdbtk_out
    tuple val('gtdbtk'), eval("gtdbtk --version | grep -Eo '[0-9]+(\\.[0-9]+)+' | head -1") , topic: versions
    path "${ID}_gtdbtk.tsv", topic: multi_qc

    script:
    """
    export GTDBTK_DATA_PATH="\$PWD/${gtdb}"
    mkdir -p gtdbtk_outdir

    gtdbtk classify_wf \\
        --genome_dir fastas \\
        --cpus ${task.cpus} \\
        -x fa \\
        --out_dir gtdbtk_outdir

    mv gtdbtk_outdir/classify/gtdbtk.bac*.summary.tsv ${ID}_gtdbtk.tsv
    """

    stub:
    """
    touch ${ID}_gtdbtk.tsv
    """
}

process GTDB_DB_DOWNLOAD {
    // https://github.com/ecogenomics/gtdbtk
    tag "r232"

    publishDir "${params.outdir}/databases"

    output:
    path("release232"), emit: gtdb_db

    script:
    """
    wget https://data.gtdb.ecogenomic.org/releases/latest/auxillary_files/gtdbtk_package/full_package/gtdbtk_data.tar.gz 
    tar xvzf gtdbtk_data.tar.gz
    rm gtdbtk_data.tar.gz
    """

    stub:
    """
    mkdir release232
    touch release232/r232.db
    """
}