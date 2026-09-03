#!/usr/bin/env nextflow

def printHelp() {
    log.info """
Usage:
    nextflow run main.nf --input manifest.csv [options]

Parameters can be passed via the command line or preferably by editing the 'qc.config' file.

Main:
    --input                             (Required) Path to input manifest, see README.md for details
    --mode                              Options: short, long, hybrid (default: short)
    --skip_preprocessing                Skip preprocessing step (default: false)
    --help                              Show this help message and exit
    --remove_host_reads                 Remove host reads from input data (default: false)

Databases:
    --sylph_db                          Path to sylph database (e.g. /path/to/.sylphdb)
    --checkm2_db                        Path to checkm2 database (e.g. /path/to/.dmnd)
    --bakta_db                          Path to bakta database (e.g. /path/to/database)

QC Options:
    --min_depth                         Minimum read coverage (default: 30)
    --target_genome_size                Assembly QC fails if genome size ±20% of target size (default: 6250000)
    --target_gc_content                 Assembly QC fails if genome GC content ±10% of target amount (default: 0.66)
    --completeness                      Threshold CheckM2 completeness score to pass QC (default: 99)
    --contamination                     Threshold CheckM2 contamination score to pass QC (default: 5)

Short Read Options:
    --fastqc_pass_criteria              Path to FASTQC pass criteria (default: "assets/fastqc_pass_criteria.json")
    --lower_assembly_length             Lower bound for assembly length when assessing read depth with fastp (default: 5500000)
    --min_contig_length                 Minimum contig length for short reads (default: 500)
    --unicycler_mode                    Unicycler mode for short reads (default: "normal")
    --reference                         Path to reference genome, used to map reads for additional QC
    --min_mapping_rate                  Threshold proportion of reads needing to map to reference during QC (default: 0.8)
    --max_error_rate                    Maximum error rate for short reads (default: 0.02)

Long Read Options:
    --long_read_platform                Platform for long reads (options: ont, pacbio) (default: ont)
    --trim_adaptors                     Trim adaptors from long reads (default: false)
    --minimum_phred_score               Minimum phred score for long reads (default: 15)
    --min_read_length                   Minimum read length for long reads (default: 1000)
    --downsample_reads                  Downsample long reads (default: false)
    --target_coverage                   Target read coverage if downsampling reads (default: 30)
    --autocycler_subsets                Number of subsets to use for autocycler (default: 4)
"""
}

def validateParams() {
    if (!params.input) {
        log.error "Error: --input parameter is required."
        exit 1
    }

    if (!file(params.input).exists()) {
        log.error "Error: Input manifest file '${params.input}' does not exist."
        exit 1
    }

    if (params.mode && !['short', 'long', 'hybrid'].contains(params.mode)) {
        log.error "Error: Invalid value for --mode. Allowed values are 'short', 'long', or 'hybrid'."
        exit 1
    }

    def validLongReadPlatforms = ["ont", "pacbio"]
    if (!(params.long_read_platform in validLongReadPlatforms)) {
        log.error "Error: Invalid long read platform, please choose: ont or pacbio"
    }
}

def validateManifest() {
    def manifestFile = file(params.input)
    if (!manifestFile.exists()) {
        log.error "Error: Manifest file '${params.input}' does not exist."
        exit 1
    }

    def requiredHeaders = [
        short: ['ID', 'R1', 'R2'],
        long: ['ID', 'long_fastq', 'genome_size'],
        hybrid: ['ID', 'R1', 'R2', 'long_fastq', 'genome_size']
    ]

    def headers = manifestFile.readLines().first().split(',')*.trim()
    def missing = requiredHeaders[params.mode]?.findAll { !headers.contains(it) }

    if (missing) {
        log.error "Error: Manifest is missing required headers for read_type '${params.read_type}': ${missing.join(', ')}"
        exit 1
    }
}

def setInputChannel() {
    def rows = Channel
        .fromPath(params.input)
        .splitCsv(header: true)

    def asFile = { path -> file(path, checkIfExists: true) }
    def parseSize = { row -> row.genome_size ? row.genome_size.toInteger() : null }

    if (params.mode == 'short') {
        return rows.map { row ->
            tuple(row.ID, [asFile(row.R1), asFile(row.R2)], null)
        }
    } else if (params.mode == 'long') {
        return rows.map { row ->
            tuple(row.ID, [asFile(row.long_fastq)], parseSize(row))
        }
    } else if (params.mode == 'hybrid') {
        return rows.map { row ->
            short_reads: tuple(row.ID, [asFile(row.R1), asFile(row.R2), asFile(row.long_fastq)], parseSize(row))
        }
    } else {
        error "Unknown params.mode: ${params.mode}"
    }
}
