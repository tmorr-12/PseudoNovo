process SYLPH_TAX {
    // https://sylph-docs.github.io/sylph-tax-quick-start/
    tag "${ID}"
    label "minimal"

    container "quay.io/biocontainers/sylph-tax:1.9.2--pyhdfd78af_0"

    publishDir "${params.outdir}/sylph", pattern: "*_sylph_taxonomy.tsv"

    input:
    tuple val(ID), path(reads), val(genome_size), path(sylph_profile), val(MODE)
    path(sylph_taxonomy)

    output:
    tuple val(ID), path(reads), val(genome_size), emit: assembly_input_ch
    path("*.sylphmpa"), emit: sylph_tax_out

    script:
    """
    sylph-tax taxprof \\
        ${sylph_profile} \\
        -t GTDB_r226 \\
        -o ${ID}_${MODE}-
    """
}