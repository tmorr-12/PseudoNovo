process SYLPH_SKETCH {
    // https://github.com/bluenote-1577/sylph
    tag "${ID}"
    label 'medium'

    container "quay.io/biocontainers/sylph:0.9.0--ha6fb395_0"

    input:
    tuple val(ID), path(reads), val(genome_size)

    output:
    tuple val(ID), path(reads), val(genome_size), path("${ID}_sketch/*.sylsp"), val(MODE), emit: sylph_sketch

    script:
    def n = reads.size()
    if (n == 2) {
        // short paired-end only
        def R1 = reads[0]
        def R2 = reads[1]
        MODE = "short"
        """
        sylph sketch -t ${task.cpus} -1 ${R1} -2 ${R2} -d ${ID}_sketch
        """
    } else {
        // long reads only
        def long_fastq = reads[0]
        MODE = "long"
        """
        sylph sketch -t ${task.cpus} -d ${ID}_sketch ${long_fastq}
        """
    }
}

process SYLPH_PROFILE {
    // https://github.com/bluenote-1577/sylph
    tag "${ID}"
    label 'medium'

    container "quay.io/biocontainers/sylph:0.9.0--ha6fb395_0"

    publishDir "${params.outdir}/${ID}", pattern: '*.tsv'

    input:
    tuple val(ID), path(reads), val(genome_size), path(sylph_sketch), val(MODE)
    path(sylph_db)

    output:
    tuple val(ID), path(reads), val(genome_size), stdout, emit: sylph_out
    path("${ID}_${MODE}_profile.tsv"), emit: sylph_tsv

    script:
    """
    sylph profile -t ${task.cpus} ${sylph_db} ${sylph_sketch} > ${ID}_${MODE}_profile.tsv

    sed -n '2p' ${ID}_${MODE}_profile.tsv \
        | awk -F'\t' '\$4 > 98 {found=1} END {print (found ? "PASS" : "FAIL")}'
    """
}
