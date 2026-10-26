process BAKTA {
    // https://github.com/oschwengers/bakta
    tag "${ID}"
    label 'huge'

    container "quay.io/biocontainers/bakta:1.12.1--pyhdfd78af_0"

    publishDir "${params.outdir}/02-ANNOTATIONS/bakta"

    input:
    tuple val(ID), path(contigs)
    path bakta_db

    output:
    tuple val(ID), path("${ID}.gff3"), emit: bakta_out
    tuple val('bakta'), eval("bakta --version | cut -d ' ' -f 2"), topic: versions
    path "${ID}.txt", topic: multi_qc

    script:
    """
    ## nf-core reccommended fix to fontconfig 'no writeable cache directory' issue
    mkdir tmp_home
    export HOME=\$PWD/tmp_home

    bakta ${contigs} --db ${bakta_db} --output annotation/ --prefix ${ID} --threads ${task.cpus}
    mv annotation/${ID}*.gff3 ${ID}.gff3
    mv annotation/${ID}*.txt ${ID}.txt
    """

    stub:
    """
    touch ${ID}.gff3
    """
}