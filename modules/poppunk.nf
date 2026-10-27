process POPPUNK {
    // https://github.com/bacpop/PopPUNK
    tag "${ID}"
    label "large"

    container "quay.io/biocontainers/poppunk:2.7.8--py310h4d0eb5b_0"

    publishDir "${params.outdir}/00-INTERMEDIATES/poppunk"

    input:
    tuple val(ID), path(contigs)
    path(poppunk_db)

    output:
    tuple val(ID), path("${ID}_clusters.tsv"), emit: poppunk_out
    tuple val('poppunk'), eval("poppunk --version | cut -d ' ' -f 2"), topic: versions

    script:
    """
    echo "${ID}_contigs\t${contigs}" > query.txt

    poppunk_assign \\
        --db ${poppunk_db} \\
        --query query.txt \\
        --output poppunk_clusters \\
        --threads ${task.cpus}
    
    mv poppunk_clusters/poppunk_clusters_clusters.csv ${ID}_clusters.csv
    tr ',' '\\t' < ${ID}_clusters.csv > ${ID}_clusters.tsv
    """

    stub:
    """
    touch ${ID}_clusters.tsv
    """
}

process POPPUNK_DB_DOWNLOAD {
    // https://bacpop.org/poppunk-databases/
    tag "P_aer_v1_refs"

    publishDir "${params.outdir}/databases"

    output:
    path("pa_v1_refs"), emit: poppunk_db

    script:
    """
    wget https://ftp.ebi.ac.uk/pub/databases/pp_dbs/Pseudomonas_aeruginosa_v1_refs.tar.bz2
    tar -xjf Pseudomonas_aeruginosa_v1_refs.tar.bz2 
    rm Pseudomonas_aeruginosa_v1_refs.tar.bz2
    """

    stub:
    """
    mkdir pa_v1_refs
    touch pa_v1_refs/pa_v1_refs.h5
    """
}