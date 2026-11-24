#!/usr/bin/env nextflow

include { SHORT_READ_QC } from '../subworkflows/short_read_qc.nf'
include { LONG_READ_QC } from '../subworkflows/long_read_qc.nf'

workflow READ_QC {

    take:
    input_ch
    sylph_db_ch

    main:
    if (params.mode == 'short') {
        SHORT_READ_QC(input_ch, sylph_db_ch).set { preprocessed_ch }

    } else if (params.mode == 'long') {
        LONG_READ_QC(input_ch, sylph_db_ch).set { preprocessed_ch }

    } else if (params.mode == 'hybrid') {
        short_reads_ch = input_ch.map { ID, reads, size -> tuple(ID, [reads[0], reads[1]], size) }
        long_reads_ch = input_ch.map { ID, reads, size -> tuple(ID, [reads[2]], size) }

        SHORT_READ_QC(short_reads_ch, sylph_db_ch)
        LONG_READ_QC(long_reads_ch, sylph_db_ch)

        SHORT_READ_QC.out.short_out_ch
            .join(LONG_READ_QC.out.long_out_ch)
            .map { ID, short_reads, size, long_reads, size2 ->
                tuple(ID, [short_reads[0], short_reads[1], long_reads], size)
            }
            .set { preprocessed_ch }
    
    } else {
        error "Unknown params.mode: '${params.mode}'. Expected 'short', 'long', or 'hybrid'."
    }

    emit:
    preprocessed_ch

}