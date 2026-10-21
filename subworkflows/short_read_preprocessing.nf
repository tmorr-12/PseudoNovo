#!/usr/bin/env nextflow

include { FASTQC } from '../modules/fastqc.nf'
include { FASTP } from '../modules/fastp.nf'
include { COLLECT_FASTQ_REPORTS 
          MERGE_REPORTS } from '../modules/reporting.nf'
          
include { DECONTAMINATION 
          CREATE_FASTQ_REPORT } from '../subworkflows/generic_preprocessing.nf'

workflow SHORT_READ_PREPROCESSING {

    take:
    input_ch

    main:
    // still run fastp to assess depth, just don't take the trimmed reads
    FASTP(input_ch)
    filter_ch = params.trim_adaptors ? FASTP.out.fastp_out_ch : input_ch
    fastp_json_ch = FASTP.out.json

    FASTQC(filter_ch)
    
    DECONTAMINATION(filter_ch)
    
    report_in_ch = DECONTAMINATION.out.reads_out_ch
        .join(FASTQC.out.r1_summary)
        .join(FASTQC.out.r2_summary)
        .join(fastp_json_ch)
        .join(DECONTAMINATION.out.sylph_tsv)
        .map { ID, reads, size, fq_r1, fq_r2, json, tsv ->
            tuple(ID, reads, size, fq_r1, fq_r2, json, tsv, [])
        }

    CREATE_FASTQ_REPORT(report_in_ch, "short")
    short_out_ch = CREATE_FASTQ_REPORT.out.out_ch

    emit:
    short_out_ch

}