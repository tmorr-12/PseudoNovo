#!/usr/bin/env nextflow

include { BAKTA } from '../modules/bakta.nf'
include { ABRICATE } from '../modules/abricate.nf'

workflow ANNOTATION {

    take:
    contigs_ch

    main:
    bakta_db_ch = Channel.value(file(params.bakta_db, checkIfExists: true))

    contigs_ch
        .multiMap { it ->
            bakta: it
            abricate: it
            // DefenceFinder (https://github.com/mdmparis/defense-finder) -> CRISPRCasFinder
            // GECCO / antiSMASH -> biosynthetic gene clusters (https://zellerlab.github.io/tools/gecco)
            // Mobile Genetic Elements (sequence indexes?)
        }
        .set { split_ch }

    BAKTA(split_ch.bakta, bakta_db_ch)
    ABRICATE(split_ch.abricate)

}