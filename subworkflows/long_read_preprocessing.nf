#!/usr/bin/env nextflow

include { NANOPLOT as NANOPLOT_PRE
          NANOPLOT as NANOPLOT_POST
          COMPARE_NANOPLOT } from '../modules/nanoplot.nf'
include { PORECHOP_ABI } from '../modules/porechop_abi.nf'
include { CHOPPER } from '../modules/chopper.nf'
include { RASUSA } from '../modules/rasusa.nf'

include { DECONTAMINATION 
          CREATE_FASTQ_REPORT } from '../subworkflows/generic_preprocessing.nf'

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

    CREATE_FASTQ_REPORT(report_in_ch, "long")
    long_out_ch = CREATE_FASTQ_REPORT.out.out_ch

    emit:
    long_out_ch

}
