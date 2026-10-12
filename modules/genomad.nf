process GENOMAD {
    // https://github.com/apcamargo/genomad
    tag "${ID}"
    label "medium"

    container "quay.io/biocontainers/genomad:1.12.0--pyhdfd78af_0"

    publishDir "${params.outdir}/genomad", pattern: "*_virus_*.tsv"

    input:
    tuple val(ID), path(contigs)
    path genomad_db

    output:
    tuple val(ID), path("${ID}_virus.fna"), emit: genomad_fna_ch
    path("${ID}_virus_summary.tsv"), emit: genomad_summary
    path("${ID}_virus_genes.tsv"), emit: genomad_genes

    script:
    """
    mkdir -p genomad_out

    genomad end-to-end \\
        --cleanup \\
        ${contigs} \\
        genomad_out \\
        ${genomad_db}

    mv genomad_out/${ID}_summary/${ID}_virus.fna ${ID}_virus.fna
    mv genomad_out/${ID}_summary/${ID}_virus_summary.tsv ${ID}_virus_summary.tsv
    mv genomad_out/${ID}_summary/${ID}_virus_genes.tsv ${ID}_virus_genes.tsv
    """
}