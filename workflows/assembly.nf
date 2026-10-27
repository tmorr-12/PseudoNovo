#!/usr/bin/env nextflow

include { UNICYCLER_SHORT } from '../modules/unicycler.nf'
include { SHOVILL } from '../modules/shovill.nf'
include { AUTOCYCLER } from '../modules/autocycler.nf'
include { FLYE } from '../modules/flye.nf'
include { MEDAKA } from '../modules/medaka.nf'
include { BWA_POLYPOLISH
          POLYPOLISH } from '../modules/polypolish.nf'
include { PYPOLCA } from '../modules/pypolca.nf'
include { QUAST } from '../modules/quast.nf'
include { CHECKM2 } from '../modules/checkm2.nf'
include { MLST } from '../modules/mlst.nf'
include { POPPUNK 
          POPPUNK_DB_DOWNLOAD } from '../modules/poppunk.nf'
include { GTDBTK } from '../modules/gtdbtk.nf'
include { COLLECT_ASSEMBLY_REPORTS 
          MERGE_REPORTS } from '../modules/reporting.nf'
include { PUBLISH_ASSEMBLY } from '../modules/publish_assembly.nf'

workflow ASSEMBLY {

    take:
    assembly_ch

    main:
    if (params.mode == "short") {
        if (params.short_assembler == "unicycler") {
            UNICYCLER_SHORT(assembly_ch)
            qc_ch = UNICYCLER_SHORT.out.fasta_ch
        } else if (params.short_assembler == "shovill") {
            SHOVILL(assembly_ch)
            qc_ch = SHOVILL.out.fasta_ch
        }

    } else if (params.mode == "long") {
            if (params.long_assembler == "autocycler") {
                AUTOCYCLER(assembly_ch)
                fasta_ch = AUTOCYCLER.out.fasta_ch
            } else if (params.long_assembler == "flye") {
                FLYE(assembly_ch)
                fasta_ch = FLYE.out.fasta_ch
            }
        MEDAKA(fasta_ch)
        qc_ch = MEDAKA.out.polished_ch

    } else if (params.mode == "hybrid") {
        AUTOCYCLER(assembly_ch)
        BWA_POLYPOLISH(AUTOCYCLER.out.fasta_ch)
        POLYPOLISH(BWA_POLYPOLISH.out.sam_out)
        PYPOLCA(POLYPOLISH.out.polished_ch)
        qc_ch = PYPOLCA.out.hybrid_ch
    }
    
    qc_ch
        .multiMap { it ->
            quast: it
            checkm2: it
            mlst: it
            poppunk: it
            gtdbtk: it
        }
        .set { split_ch }

    QUAST(split_ch.quast)

    checkm2_db = Channel.value(file(params.checkm2_db, checkIfExists: true))
    CHECKM2(split_ch.checkm2, checkm2_db)

    MLST(split_ch.mlst)

    if (params.poppunk_db) {
        poppunk_db = Channel.value(file(params.poppunk_db, checkIfExists: true))
    } else {
        POPPUNK_DB_DOWNLOAD()
        poppunk_db = POPPUNK_DB_DOWNLOAD.out.poppunk_db
    }
    POPPUNK(split_ch.poppunk, poppunk_db)

    GTDBTK(split_ch.gtdbtk)

    report_ch = qc_ch
        .join(QUAST.out.quast_out)
        .join(CHECKM2.out.checkm2_out)
        .join(POPPUNK.out.poppunk_out)
        .join(MLST.out.mlst_out)
        .join(GTDBTK.out.gtdbtk_out)
        .map { it ->
            tuple(it[0], it[1], it[2..-1])
        }

    COLLECT_ASSEMBLY_REPORTS(report_ch)

    merge_ch = COLLECT_ASSEMBLY_REPORTS.out.report.collect()
    MERGE_REPORTS(merge_ch, "assembly_report")

    COLLECT_ASSEMBLY_REPORTS.out.contigs
        | filter { it -> it[2].trim() == 'PASS' }
        | map { it -> it[0..1] }
        | set { contigs_ch }

    PUBLISH_ASSEMBLY(contigs_ch)

    emit:
    contigs_ch

}