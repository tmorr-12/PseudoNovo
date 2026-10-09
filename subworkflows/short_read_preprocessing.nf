#!/usr/bin/env nextflow

include { FASTQC 
          FILTER_FASTQC } from '../modules/fastqc.nf'
include { FASTP 
          FILTER_FASTP } from '../modules/fastp.nf'
          
include { DECONTAMINATION } from '../subworkflows/decontamination.nf'

workflow SHORT_READ_PREPROCESSING {

    take:
    input_ch

    main:
    FASTQC(input_ch)
    
    FILTER_FASTQC(FASTQC.out.zip)
    | filter { it -> it[3].trim() == 'PASS' }
    | map { it -> it[0..2] }
    | set { fastqc_out_ch }
    
    FASTP(fastqc_out_ch)

    FILTER_FASTP(FASTP.out.fastp)
    | filter { it -> it[3].trim() == 'PASS' }
    | map { it -> it[0..2] }
    | DECONTAMINATION
    | set { short_out_ch }
    
    emit:
    short_out_ch

}