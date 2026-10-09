process PYPOLCA {
    // https://github.com/gbouras13/pypolca
    tag "${ID}"
    label 'medium'

    publishDir "${params.outdir}/assemblies", pattern: "*.fasta"

    container "quay.io/biocontainers/pypolca:0.5.0--pyhdfd78af_0"

    input:
    tuple val(ID), path(reads), path(fasta)

    output:
    tuple val(ID), path("${ID}_hybrid.fasta"), emit: hybrid_ch

    script:
    def R1="${reads[0]}"
    def R2="${reads[1]}"
    """
    mkdir -p pypolca_out

    pypolca run \\
        -a ${fasta} \\
        -1 ${R1} \\
        -2 ${R2} \\
        -t ${task.cpus} \\
        -p ${ID} \\
        -o pypolca_out \\
        --careful

    mv pypolca_out/${ID}_corrected.fasta ${ID}_hybrid.fasta
    """
}