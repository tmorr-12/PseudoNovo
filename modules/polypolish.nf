process BWA_POLYPOLISH {
    // https://github.com/bwa-mem2/bwa-mem2
    tag "${ID}"
    label 'medium'

    container "quay.io/biocontainers/bwa-mem2:2.3--he70b90d_0"

    input:
    tuple val(ID), path(reads), path(fasta)

    output:
    tuple val(ID), path(reads), path(fasta), path("${ID}_1.sam"), path("${ID}_2.sam"), emit: sam_out
    tuple val('bwamem2'), eval('bwa-mem2 version | grep -o -E "[0-9]+(\\.[0-9]+)+"'), topic: versions

    script:
    def R1="${reads[0]}"
    def R2="${reads[1]}"
    """
    bwa-mem2 index ${fasta}
    bwa-mem2 mem -t ${task.cpus} -a ${fasta} ${R1} > ${ID}_1.sam
    bwa-mem2 mem -t ${task.cpus} -a ${fasta} ${R2} > ${ID}_2.sam
    """

    stub:
    """
    touch ${ID}_1.sam
    touch ${ID}_2.sam
    """
}

process POLYPOLISH {
    // https://github.com/rrwick/Polypolish
    tag "${ID}"
    label 'medium'

    container "quay.io/biocontainers/polypolish:0.7.1--hec9b1f2_0"

    input:
    tuple val(ID), path(reads), path(fasta), path(sam_1), path(sam_2)

    output:
    tuple val(ID), path(reads), path("${ID}_polished.fasta"), emit: polished_ch
    tuple val('polypolish'), eval("polypolish polish --version | sed '1!d;s/Polypolish-polish //'"), topic: versions

    script:
    """
    polypolish filter \\
        --in1 ${sam_1} \\
        --in2 ${sam_2} \\
        --out1 filtered_1.sam \\
        --out2 filtered_2.sam

    polypolish polish ${fasta} filtered_1.sam filtered_2.sam > ${ID}_polished.fasta
    rm *.amb *.ann *.bwt *.pac *.sa *.sam
    """

    stub:
    """
    touch ${ID}_polished.fasta
    """
}