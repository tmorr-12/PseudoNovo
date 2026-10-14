#!/usr/bin/env nextflow

include { NANOPLOT as NANOPLOT_PRE
          NANOPLOT as NANOPLOT_POST
          COMPARE_NANOPLOT } from '../modules/nanoplot.nf'
include { PORECHOP_ABI } from '../modules/porechop_abi.nf'
include { CHOPPER } from '../modules/chopper.nf'
include { RASUSA } from '../modules/rasusa.nf'
include { COLLECT_FASTQ_REPORTS 
          MERGE_REPORTS } from '../modules/reporting.nf'

include { DECONTAMINATION } from '../subworkflows/decontamination.nf'

workflow LONG_READ_PREPROCESSING {

    take:
    input_ch

    main:
    NANOPLOT_PRE(input_ch, "pre")

    if (params.trim_adaptors) {
        PORECHOP_ABI(input_ch)
        | set { filter_ch }
    } else {
        filter_ch = input_ch
    }
    
    CHOPPER(filter_ch)
    | DECONTAMINATION

    if (params.downsample_reads) {
        RASUSA(DECONTAMINATION.out.reads_out_ch)
        | set { filtered_reads_ch }
    } else {
        filtered_reads_ch = DECONTAMINATION.out.reads_out_ch
    }

    NANOPLOT_POST(filtered_reads_ch, "post")

    summary_ch = NANOPLOT_PRE.out.nanostats
        .join(NANOPLOT_POST.out.nanostats)

    COMPARE_NANOPLOT(summary_ch)

    report_in_ch = filtered_reads_ch
        .join(DECONTAMINATION.out.sylph_tsv)
        .join(NANOPLOT_POST.out.nanostats)
        .map { ID, reads, size, tsv, stats ->
            tuple(ID, reads, size, [], [], [], tsv, stats)
        }

    COLLECT_FASTQ_REPORTS(report_in_ch)

    COLLECT_FASTQ_REPORTS.out.qc_status
    | filter { it -> it[3].trim() == 'PASS' }
    | map { it -> it[0..2] }
    | set { long_out_ch }

    merge_ch = COLLECT_FASTQ_REPORTS.out.report.collect()
    MERGE_REPORTS(merge_ch, "long-read-qc-report")

    emit:
    long_out_ch

}
