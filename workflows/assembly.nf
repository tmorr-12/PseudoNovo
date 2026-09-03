#!/usr/bin/env nextflow

include { UNICYCLER_SHORT
          UNICYCLER_HYBRID } from '../modules/unicycler.nf'
include { AUTOCYCLER } from '../modules/autocycler.nf'
include { QUAST } from '../modules/quast.nf'
include { CHECKM2 } from '../modules/checkm2.nf'
include { MLST } from '../modules/mlst.nf'
include { COLLECT_REPORTS 
          MERGE_REPORTS } from '../modules/reporting.nf'

workflow ASSEMBLY {

    take:
    assembly_ch

    main:
    if (params.mode == "short") {
        UNICYCLER_SHORT(assembly_ch)
        qc_ch = UNICYCLER_SHORT.out.fasta_ch

    } else if (params.mode == "long") {
        AUTOCYCLER(assembly_ch)
        qc_ch = AUTOCYCLER.out.fasta_ch
        
    } else if (params.mode == "hybrid") {
        UNICYCLER_HYBRID(assembly_ch)
        qc_ch = UNICYCLER_HYBRID.out.fasta_ch
    }
    
    qc_ch
        .multiMap { it ->
            quast: it
            checkm2: it
            mlst: it
        }
        .set { split_ch }

    QUAST(split_ch.quast)

    checkm2_db = Channel.value(file(params.checkm2_db, checkIfExists: true))
    CHECKM2(split_ch.checkm2, checkm2_db)

    MLST(split_ch.mlst)

    report_ch = qc_ch
        .join(QUAST.out.quast_out)
        .join(CHECKM2.out.checkm2_out)
        .join(MLST.out.mlst_out)
        .map { it ->
            tuple(it[0], it[1], it[2..-1])
        }

    COLLECT_REPORTS(report_ch)

    merge_ch = COLLECT_REPORTS.out.report.collect()
    MERGE_REPORTS(merge_ch)

    COLLECT_REPORTS.out.contigs
        | filter { it -> it[2].trim() == 'PASS' }
        | map { it -> it[0..1] }
        | set { contigs_ch }

    emit:
    contigs_ch

}