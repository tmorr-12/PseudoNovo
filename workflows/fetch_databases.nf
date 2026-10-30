#!/usr/bin/env nextflow

include { SYLPH_DB_DOWNLOAD } from '../modules/sylph.nf'
include { CHECKM2_DB_DOWNLOAD} from '../modules/checkm2.nf'
include { POPPUNK_DB_DOWNLOAD } from '../modules/poppunk.nf'
include { GTDB_DB_DOWNLOAD } from '../modules/gtdbtk.nf'
include { BAKTA_DB_DOWNLOAD } from '../modules/bakta.nf'
include { CARD_DB_DOWNLOAD } from '../modules/rgi.nf'
include { GENOMAD_DB_DOWNLOAD } from '../modules/genomad.nf'
include { CHECKV_DB_DOWNLOAD } from '../modules/checkv.nf'
include { DEFENSE_FINDER_MODELS_DOWNLOAD } from '../modules/defense_finder.nf'

workflow FETCH_DATABASES {

    main:
    if (!params.sylph_db) {
        SYLPH_DB_DOWNLOAD()
    }
    if (!params.checkm2_db) {
        CHECKM2_DB_DOWNLOAD()
    }
    if (!params.poppunk_db) {
        POPPUNK_DB_DOWNLOAD()
    }
    if (!params.gtdb) {
        GTDB_DB_DOWNLOAD()
    }
    if (!params.bakta_db) {
        BAKTA_DB_DOWNLOAD()
    }
    if (!params.card_db) {
        CARD_DB_DOWNLOAD()
    }
    if (!params.genomad_db) {
        GENOMAD_DB_DOWNLOAD()
    }
    if (!params.checkv_db) {
        CHECKV_DB_DOWNLOAD()
    }
    if (!params.defensefinder_models) {
        DEFENSE_FINDER_MODELS_DOWNLOAD()
    }

    emit:
    sylph_db_ch = params.sylph_db ? Channel.value(file(params.sylph_db, checkIfExists: true)) : SYLPH_DB_DOWNLOAD.out.sylph_db
    checkm2_db_ch = params.checkm2_db ? Channel.value(file(params.checkm2_db, checkIfExists: true)) : CHECKM2_DB_DOWNLOAD.out.checkm2_db
    poppunk_db_ch = params.poppunk_db ? Channel.value(file(params.poppunk_db, checkIfExists: true)) : POPPUNK_DB_DOWNLOAD.out.poppunk_db
    gtdb_db_ch = params.gtdb ? Channel.value(file(params.gtdb, checkIfExists: true)) : GTDB_DB_DOWNLOAD.out.gtdb_db
    bakta_db_ch = params.bakta_db ? Channel.value(file(params.bakta_db, checkIfExists: true)) : BAKTA_DB_DOWNLOAD.out.bakta_db
    card_db_ch = params.card_db ? Channel.fromPath("${params.card_db}/*", checkIfExists: true).collect() : CARD_DB_DOWNLOAD.out.card_db
    genomad_db_ch = params.genomad_db ? Channel.value(file(params.genomad_db, checkIfExists: true)) : GENOMAD_DB_DOWNLOAD.out.genomad_db
    checkv_db_ch = params.checkv_db ? Channel.value(file(params.checkv_db, checkIfExists: true)) : CHECKV_DB_DOWNLOAD.out.checkv_db
    defensefinder_models_ch = params.defensefinder_models ? Channel.value(file(params.defensefinder_models, checkIfExists: true)) : DEFENSE_FINDER_MODELS_DOWNLOAD.out.defensefinder_models

}