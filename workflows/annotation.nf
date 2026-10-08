#!/usr/bin/env nextflow

include { BAKTA } from '../modules/bakta.nf'
include { ABRICATE } from '../modules/abricate.nf'
include { RGI } from '../modules/rgi.nf'

workflow ANNOTATION {

    take:
    contigs_ch

    main:
    bakta_db_ch = Channel.value(file(params.bakta_db, checkIfExists: true))
    card_db_ch = Channel.fromPath("${params.card_db}/*", checkIfExists: true).collect()

    contigs_ch
        .multiMap { it ->
            bakta: it
            abricate: it
            rgi: it
            // DefenceFinder (https://github.com/mdmparis/defense-finder) -> CRISPRCasFinder
            // GECCO / antiSMASH -> biosynthetic gene clusters (https://zellerlab.github.io/tools/gecco)
        }
        .set { split_ch }

    BAKTA(split_ch.bakta, bakta_db_ch)
    ABRICATE(split_ch.abricate)
    RGI(split_ch.rgi, card_db_ch)

}