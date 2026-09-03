process CHOPPER {
    // https://github.com/wdecoster/chopper
    tag "${ID}"
    label 'small'

    container "quay.io/biocontainers/chopper:0.13.0--h7f49ad2_0"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path("${ID}_chopper.fastq", arity: '1'), val(size), emit: chopper_out

    script:
    def long_fastq="${reads[0]}"
    """
    chopper \
        -q ${params.minimum_phred_score} \
        -l ${params.min_read_length} \
        -t ${task.cpus} \
        -i ${long_fastq} \
    > ${ID}_chopper.fastq
    """
}