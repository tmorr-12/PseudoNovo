process SEQTK {
    // https://github.com/lh3/seqtk
    tag "${ID}"
    label "small"

    container "quay.io/biocontainers/seqtk:1.5--h577a1d6_1"

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path("${ID}_R{1,2}_subsampled.fq.gz"), val(size), emit: seqtk_out_ch
    tuple val('seqtk'), eval("seqtk 2>&1 | sed -n 's/^Version: //p'"), topic: versions

    script:
    def R1="${reads[0]}"
    def R2="${reads[1]}"
    """
    seqtk sample -s100 ${R1} 4500000 | gzip > ${ID}_R1_subsampled.fq.gz
    seqtk sample -s100 ${R2} 4500000 | gzip > ${ID}_R2_subsampled.fq.gz
    """

    stub:
    """
    touch ${ID}_R{1,2}_subsampled.fq.gz
    """
}