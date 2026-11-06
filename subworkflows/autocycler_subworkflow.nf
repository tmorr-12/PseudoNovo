#!/usr/bin/env nextflow

include { AUTOCYCLER_SUBSAMPLE
          AUTOCYCLER_ASSEMBLE
          AUTOCYCLER_COMPRESS
          AUTOCYCLER_CLUSTER_AND_COMBINE } from '../modules/autocycler.nf'

workflow AUTOCYCLER {

    take:
    assembly_ch

    main:
    AUTOCYCLER_SUBSAMPLE(assembly_ch)
    | AUTOCYCLER_ASSEMBLE
    | AUTOCYCLER_COMPRESS
    | AUTOCYCLER_CLUSTER_AND_COMBINE

    fasta_ch = AUTOCYCLER_CLUSTER_AND_COMBINE.out.fasta_ch

    emit:
    fasta_ch
}