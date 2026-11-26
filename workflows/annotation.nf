#!/usr/bin/env nextflow

include { BAKTA } from '../modules/bakta.nf'
include { ABRICATE } from '../modules/abricate.nf'
include { RGI } from '../modules/rgi.nf'
include { DEFENSE_FINDER } from '../modules/defense_finder.nf'
include { GAPSEQ } from '../modules/gapseq.nf'

workflow ANNOTATION {

    take:
    contigs_ch
    bakta_db_ch
    card_db_ch
    defensefinder_models_ch
    gapseq_db_ch

    main:
    contigs_ch
        .multiMap { it ->
            bakta: it
            abricate: it
            rgi: it
            defensefinder: it
            gapseq: it
        }
        .set { split_ch }

    // BAKTA(split_ch.bakta, bakta_db_ch)
    ABRICATE(split_ch.abricate)
    RGI(split_ch.rgi, card_db_ch)
    DEFENSE_FINDER(split_ch.defensefinder, defensefinder_models_ch)
    // GAPSEQ(split_ch.gapseq, gapseq_db_ch)

}