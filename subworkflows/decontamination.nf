#!/usr/bin/env nextflow

include { KRAKEN2 
          PARSE_KRAKEN2 } from '../modules/kraken2.nf'
include { HOSTILE } from '../modules/hostile.nf'
include { SYLPH_SKETCH 
          SYLPH_PROFILE } from '../modules/sylph.nf'
include { SYLPH_TAX } from '../modules/sylph-tax.nf'

workflow DECONTAMINATION {

    take:
    preprocessed_ch

    main:
    if (params.remove_host_reads) {
        kraken_db_ch = Channel.value(file(params.kraken2_db, checkIfExists: true))
        KRAKEN2(preprocessed_ch, kraken_db_ch)
        | PARSE_KRAKEN2

        PARSE_KRAKEN2.out
            .branch { ID, reads, size, status -> 
                failed: status.trim() == 'FAIL'
                passed: status.trim() == 'PASS'
            }
            .set { host_removal_ch }

        HOSTILE(host_removal_ch.failed.map { it -> it[0..2] })

        cleaned_ch = HOSTILE.out.cleaned_reads.mix(host_removal_ch.passed.map { it -> it[0..2] })
    } else {
        cleaned_ch = preprocessed_ch
    }

    SYLPH_SKETCH(cleaned_ch)

    SYLPH_SKETCH.out.sylph_sketch.set { sylph_profile_ch }
    sylph_db_ch = Channel.value(file(params.sylph_db, checkIfExists: true))

    SYLPH_PROFILE(sylph_profile_ch, sylph_db_ch)

    SYLPH_PROFILE.out.sylph_out
    | filter { it -> it[5].trim() == 'PASS' }
    | map { it -> it[0..4] }
    | set { sylph_out_ch }

    sylph_taxonomy = channel.value(file(params.sylph_taxonomy, checkIfExists: true))
    SYLPH_TAX(sylph_out_ch, sylph_taxonomy)

    emit:
    SYLPH_TAX.out.assembly_input_ch

}