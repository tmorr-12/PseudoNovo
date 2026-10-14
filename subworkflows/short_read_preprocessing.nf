#!/usr/bin/env nextflow

include { FASTQC } from '../modules/fastqc.nf'
include { FASTP } from '../modules/fastp.nf'
include { COLLECT_FASTQ_REPORTS 
          MERGE_REPORTS } from '../modules/reporting.nf'
          
include { DECONTAMINATION } from '../subworkflows/decontamination.nf'

workflow SHORT_READ_PREPROCESSING {

    take:
    input_ch

    main:
    FASTQC(input_ch)

    FASTP(input_ch)

    DECONTAMINATION(FASTP.out.fastp_out_ch)
    
    report_in_ch = DECONTAMINATION.out.reads_out_ch
        .join(FASTQC.out.r1_summary)
        .join(FASTQC.out.r2_summary)
        .join(FASTP.out.json)
        .join(DECONTAMINATION.out.sylph_tsv)
        .map { ID, reads, size, fq_r1, fq_r2, json, tsv ->
            tuple(ID, reads, size, fq_r1, fq_r2, json, tsv, [])
        }

    COLLECT_FASTQ_REPORTS(report_in_ch)

    COLLECT_FASTQ_REPORTS.out.qc_status
    | filter { it -> it[3].trim() == 'PASS' }
    | map { it -> it[0..2] }
    | set { short_out_ch }

    merge_ch = COLLECT_FASTQ_REPORTS.out.report.collect()
    MERGE_REPORTS(merge_ch, "short-read-qc-report")

    emit:
    short_out_ch

}