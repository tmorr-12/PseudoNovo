#!/usr/bin/env nextflow

include { NANOPLOT as NANOPLOT_PRE
          NANOPLOT as NANOPLOT_POST
          FILTER_NANOPLOT 
          COMPARE_NANOPLOT } from '../modules/nanoplot.nf'
include { PORECHOP_ABI } from '../modules/porechop_abi.nf'
include { CHOPPER } from '../modules/chopper.nf'
include { RASUSA } from '../modules/rasusa.nf'

include { DECONTAMINATION } from '../subworkflows/decontamination.nf'

workflow LONG_READ_PREPROCESSING {

    take:
    input_ch

    main:
    NANOPLOT_PRE(input_ch, "pre")
    
    FILTER_NANOPLOT(NANOPLOT_PRE.out.nanostats)
    | filter { it -> it[3].trim() == 'PASS' }
    | map { it -> it[0..2] }
    | set { nanoplot_out_ch }

    NANOPLOT_PRE.out.nanostats
    | map { it -> tuple(it[0], it[3]) }
    | set { prefilter_report_ch}

    if (params.trim_adaptors) {
        PORECHOP_ABI(nanoplot_out_ch)
        | set { filter_ch }
    } else {
        filter_ch = nanoplot_out_ch
    }

    CHOPPER(filter_ch)
    | DECONTAMINATION

    if (params.downsample_reads) {
        RASUSA(DECONTAMINATION.out)
        | set { long_out_ch }
    } else {
        long_out_ch = DECONTAMINATION.out
    }

    NANOPLOT_POST(long_out_ch, "post")

    NANOPLOT_POST.out.nanostats
    | map { it -> tuple(it[0], it[3]) }
    | set { postfilter_report_ch}

    summary_ch = prefilter_report_ch
        .join(postfilter_report_ch)

    COMPARE_NANOPLOT(summary_ch)

    emit:
    long_out_ch

}
