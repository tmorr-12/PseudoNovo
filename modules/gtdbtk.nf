process GTDBTK {
    // https://github.com/ecogenomics/gtdbtk
    tag "${ID}"
    label "mega"

    container "quay.io/biocontainers/gtdbtk:2.7.2--pyhdfd78af_1"

    publishDir "${params.outdir}/gtdbtk"

    input:
    tuple val(ID), path(contigs, stageAs: "fastas/*")

    output:
    path("${ID}_gtdbtk.tsv"), emit: gtdbtk_out

    script:
    def report_tsv = "${ID}_gtdbtk.tsv"
    """
    export GTDBTK_DATA_PATH="${params.gtdb}"
    mkdir -p gtdbtk_outdir

    gtdbtk classify_wf \\
        --genome_dir fastas \\
        --skip_ani_screen \\
        --cpus ${task.cpus} \\
        -x fa \\
        --out_dir gtdbtk_outdir

    mv gtdbtk_outdir/gtdbtk.bac*.summary.tsv ${report_tsv}
    """
}