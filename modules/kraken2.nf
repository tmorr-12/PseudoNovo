process KRAKEN2 {
    // https://github.com/DerrickWood/kraken2
    tag "${ID}"
    label "mega"

    container "quay.io/biocontainers/kraken2:2.17.2--pl5321h3be2455_0"

    publishDir "${params.outdir}/kraken2", pattern: '*.tsv'
}