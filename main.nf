#!/usr/bin/env nextflow

include { printHelp 
          validateParams 
          setInputChannel 
          validateManifest } from './modules/helper_functions.nf'

include { PREPROCESSING } from './workflows/preprocessing.nf'
include { ASSEMBLY } from './workflows/assembly.nf'
include { ANNOTATION } from './workflows/annotation.nf'
include { FETCH_DATABASES } from './workflows/fetch_databases.nf'

include { MULTIQC } from './modules/multiqc.nf'

workflow {

    if (params.help) {
        printHelp()
        exit 0
    }

    validateParams()
    validateManifest()

    input_ch = setInputChannel()

    FETCH_DATABASES()

    sylph_db_ch = FETCH_DATABASES.out.sylph_db_ch
    checkm2_db_ch = FETCH_DATABASES.out.checkm2_db_ch
    poppunk_db_ch = FETCH_DATABASES.out.poppunk_db_ch
    gtdb_db_ch = FETCH_DATABASES.out.gtdb_db_ch
    bakta_db_ch = FETCH_DATABASES.out.bakta_db_ch
    card_db_ch = FETCH_DATABASES.out.card_db_ch
    genomad_db_ch = FETCH_DATABASES.out.genomad_db_ch
    checkv_db_ch = FETCH_DATABASES.out.checkv_db_ch

    def assembly_ch
    if (!params.skip_preprocessing) {
        PREPROCESSING(
            input_ch, 
            sylph_db_ch
        )
        assembly_ch = PREPROCESSING.out.preprocessed_ch
    } else {
        assembly_ch = input_ch
    }

    ASSEMBLY(
        assembly_ch,
        checkm2_db_ch,
        poppunk_db_ch,
        gtdb_db_ch
    )
    
    ANNOTATION(
        ASSEMBLY.out.contigs_ch,
        bakta_db_ch,
        card_db_ch,
        genomad_db_ch,
        checkv_db_ch
    )

    multi_qc_ch = channel.topic('multi_qc').collect()
    MULTIQC(multi_qc_ch)

    channel.topic('versions')
        .unique()
        .map { tool, version -> "${tool}\t${version}" }
        .collectFile(
            storeDir: "${params.outdir}/pipeline-info",
            name: 'software_versions.tsv',
            newLine: true,
            sort: true
        )

}
