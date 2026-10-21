#!/usr/bin/env nextflow

// include { BAKTA } from '../modules/bakta.nf'
include { ABRICATE } from '../modules/abricate.nf'
include { RGI } from '../modules/rgi.nf'
include { GENOMAD } from '../modules/genomad.nf'
include { CHECKV } from '../modules/checkv.nf'
include { DEFENSE_FINDER } from '../modules/defense_finder.nf'

workflow ANNOTATION {

    take:
    contigs_ch

    main:
    // bakta_db_ch = Channel.value(file(params.bakta_db, checkIfExists: true))
    card_db_ch = Channel.fromPath("${params.card_db}/*", checkIfExists: true).collect()
    genomad_db_ch = Channel.value(file(params.genomad_db, checkIfExists: true))
    defensefinder_models = Channel.value(file(params.defensefinder_models, checkIfExists: true))

    contigs_ch
        .multiMap { it ->
            // bakta: it
            abricate: it
            rgi: it
            genomad: it
            defensefinder: it
        }
        .set { split_ch }

    // BAKTA(split_ch.bakta, bakta_db_ch)
    ABRICATE(split_ch.abricate)
    RGI(split_ch.rgi, card_db_ch)

    GENOMAD(split_ch.genomad, genomad_db_ch)
    checkv_input_ch = GENOMAD.out.genomad_fna_ch
    CHECKV(checkv_input_ch)

    DEFENSE_FINDER(split_ch.defensefinder, defensefinder_models)

}