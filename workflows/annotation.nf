#!/usr/bin/env nextflow

include { BAKTA } from '../modules/bakta.nf'
include { ABRICATE } from '../modules/abricate.nf'
include { RGI } from '../modules/rgi.nf'
include { GENOMAD } from '../modules/genomad.nf'
include { CHECKV } from '../modules/checkv.nf'
include { DEFENSE_FINDER } from '../modules/defense_finder.nf'

workflow ANNOTATION {

    take:
    contigs_ch
    bakta_db_ch
    card_db_ch
    genomad_db_ch
    checkv_db_ch
    defensefinder_models_ch

    main:
    contigs_ch
        .multiMap { it ->
            bakta: it
            abricate: it
            rgi: it
            genomad: it
            defensefinder: it
        }
        .set { split_ch }

    BAKTA(split_ch.bakta, bakta_db_ch)
    ABRICATE(split_ch.abricate)
    RGI(split_ch.rgi, card_db_ch)
    DEFENSE_FINDER(split_ch.defensefinder, defensefinder_models_ch)

    GENOMAD(split_ch.genomad, genomad_db_ch)
    CHECKV(GENOMAD.out.genomad_fna_ch, checkv_db_ch)

}