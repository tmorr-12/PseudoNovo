process PORECHOP_ABI {
    tag "${ID}"
    label "small"

    container "quay.io/biocontainers/porechop_abi:0.5.1--py310h275bdba_0"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path("${ID}_trimmed.fastq", arity: '1'), val(size), emit: trimmed_fastq
    tuple val('porechop_abi'), eval("porechop_abi --version"), topic: versions
    
    script:
    def long_fastq="${reads[0]}"
    """
    porechop_abi --ab_initio -i ${long_fastq} -o ${ID}_trimmed.fastq --threads ${task.cpus}
    """

    stub:
    """
    touch ${ID}_trimmed.fastq
    """
}