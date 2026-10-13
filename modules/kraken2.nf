process KRAKEN2 {
    // https://github.com/DerrickWood/kraken2
    tag "${ID}"
    label "mega"

    container "quay.io/biocontainers/kraken2:2.17.2--pl5321h3be2455_0"

    input:
    tuple val(ID), path(reads), val(size)
    path(kraken2_db)

    output:
    tuple val(ID), path(reads), val(size), path("report.txt")

    script:
    def n = reads.size()
    def paired = n == 2 ? "--paired" : ""
    """
    k2 classify \\
        --db ${kraken2_db} \\
        --threads ${task.cpus} \\
        --output output.txt \\
        ${paired} \\
        --report report.txt \\
        ${reads.join(' ')} \\
        1>&2
    """
}

process PARSE_KRAKEN2 {
    tag "${ID}"
    label "minimal"

    container "quay.io/biocontainers/pandas:2.2.1"

    input:
    tuple val(ID), path(reads), val(size), path(report)

    output:
    tuple val(ID), path(reads), val(size), stdout, emit: kraken2_out

    script:
    def command = "${projectDir}/bin/parse_kraken2.py"
    """
    ${command} ${report}
    """
}