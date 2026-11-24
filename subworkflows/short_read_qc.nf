#!/usr/bin/env nextflow

include { FASTQC } from '../modules/fastqc.nf'
include { FASTP } from '../modules/fastp.nf'
include { SHORT_READ_DEPTH } from '../modules/short_read_depth.nf'
include { SEQTK } from '../modules/seqtk.nf'
include { COLLECT_FASTQ_REPORTS 
          MERGE_REPORTS } from '../modules/reporting.nf'
          
include { DECONTAMINATION 
          CREATE_FASTQ_REPORT } from '../subworkflows/subworkflows.nf'

workflow SHORT_READ_QC {

    take:
    input_ch
    sylph_db_ch

    main:
    if (params.trim_adaptors) {
        FASTP(input_ch)
        filter_ch = FASTP.out.fastp_out_ch
    } else {
        filter_ch = input_ch
    }

    SHORT_READ_DEPTH(filter_ch)
    FASTQC(filter_ch)
    DECONTAMINATION(filter_ch, sylph_db_ch)

    if (params.downsample_reads) {
        SEQTK(DECONTAMINATION.out.reads_out_ch)
        filtered_reads_ch = SEQTK.out.seqtk_out_ch
    } else {
        filtered_reads_ch = DECONTAMINATION.out.reads_out_ch
    }
    
    report_in_ch = filtered_reads_ch
        .join(FASTQC.out.r1_summary)
        .join(FASTQC.out.r2_summary)
        .join(SHORT_READ_DEPTH.out.depth)
        .join(DECONTAMINATION.out.sylph_tsv)
        .map { ID, reads, size, fq_r1, fq_r2, depth, tsv ->
            tuple(ID, reads, size, fq_r1, fq_r2, depth, tsv, [])
        }

    CREATE_FASTQ_REPORT(report_in_ch, "short_read_qc_report")
    short_out_ch = CREATE_FASTQ_REPORT.out.out_ch

    emit:
    short_out_ch

}