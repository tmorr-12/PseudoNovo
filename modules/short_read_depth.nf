process SHORT_READ_DEPTH {
    tag "${ID}"
    label "tiny"

    container "quay.io/biocontainers/pandas:2.2.1"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), stdout, emit: depth

    script:
    def command = "${projectDir}/bin/short_read_depth.py"
    def R1 = "${reads[0]}"
    """
    ${command} ${R1} ${params.lower_assembly_length}
    """

    stub:
    """
    echo "PASS"
    """
}