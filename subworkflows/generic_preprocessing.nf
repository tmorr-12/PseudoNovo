#!/usr/bin/env nextflow

include { SYLPH_SKETCH 
          SYLPH_PROFILE 
          SYLPH_DB_DOWNLOAD } from '../modules/sylph.nf'
include { COLLECT_FASTQ_REPORTS 
          MERGE_REPORTS } from '../modules/reporting.nf'

workflow DECONTAMINATION {

    take:
    preprocessed_ch

    main:
    SYLPH_SKETCH(preprocessed_ch)

    SYLPH_SKETCH.out.sylph_sketch.set { sylph_profile_ch }

    if (params.sylph_db) {
        sylph_db_ch = Channel.value(file(params.sylph_db, checkIfExists: true))
    } else {
        SYLPH_DB_DOWNLOAD()
        sylph_db_ch = SYLPH_DB_DOWNLOAD.out.sylph_db
    }

    SYLPH_PROFILE(sylph_profile_ch, sylph_db_ch)

    emit:
    reads_out_ch = SYLPH_PROFILE.out.reads_out
    sylph_tsv = SYLPH_PROFILE.out.sylph_tsv

}

workflow CREATE_FASTQ_REPORT {

    take:
    report_in_ch
    name

    main:
    COLLECT_FASTQ_REPORTS(report_in_ch)

    COLLECT_FASTQ_REPORTS.out.qc_status
    | filter { it -> it[3].trim() == 'PASS' }
    | map { it -> it[0..2] }
    | set { out_ch }

    merge_ch = COLLECT_FASTQ_REPORTS.out.report.collect()
    MERGE_REPORTS(merge_ch, name)

    emit: out_ch
    
}