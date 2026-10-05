process GUNZIP {
    tag "${ID}"
    label 'small'
    scratch true

    input:
    tuple val(ID), path(reads), val(size)

    output:
    tuple val(ID), path("decompressed_reads/*", arity: '1..3'), val(size), emit: reads_ch

    script:
    """
    mkdir -p decompressed_reads

    for f in ${reads}; do
        if [[ "\$f" == *.gz ]]; then
            gunzip -c "\$f" > "decompressed_reads/\${f%.gz}"
        else
            mv "\$f" decompressed_reads/
        fi
    done
    """
}