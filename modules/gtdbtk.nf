process GTDBTK {
    // https://github.com/ecogenomics/gtdbtk
    tag "${ID}"
    label "gtdb"

    container "quay.io/biocontainers/gtdbtk:2.7.2--pyhdfd78af_1"

    publishDir "${params.outdir}/00-INTERMEDIATES/gtdbtk"

    input:
    tuple val(ID), path(contigs, stageAs: "fastas/*")

    output:
    tuple val(ID), path("${ID}_gtdbtk.tsv"), emit: gtdbtk_out
    tuple val('gtdbtk'), eval("gtdbtk --version | grep -Eo '[0-9]+(\\.[0-9]+)+' | head -1") , topic: versions
    path "${ID}_gtdbtk.tsv", topic: multi_qc

    script:
    """
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