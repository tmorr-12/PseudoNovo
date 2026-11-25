#!/usr/bin/env python3

import argparse
import json
from pathlib import Path
import gzip

import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser(description="Combine fastq qc reports into one")
    parser.add_argument("--id", type=str, required=True, help="ID of sample")
    parser.add_argument("--mode", type=str, required=True, choices=["short", "long"], help="Short or long reads")
    parser.add_argument("--min_depth", type=int, required=True, help="Minimum read depth parameter")
    parser.add_argument("--lower_assembly_length", type=int, help="Lower bound for P.aer genome size")
    parser.add_argument("--sylph_profile", type=Path, help="Path to sylph profile .tsv")

    short = parser.add_argument_group("FastQC")
    short.add_argument("--fastqc_r1", type=Path, help="Path for FastQC R1 summary")
    short.add_argument("--fastqc_r2", type=Path, help="Path for FastQC R2 summary")
    short.add_argument("--pass_criteria_json", type=Path, help="Path to FastQC pass criteria json")
    short.add_argument("--sample_fq", type=Path, help="Path to fastq for read depth calculation")

    long = parser.add_argument_group("Nanoplot")
    long.add_argument("--nanoplot_out", type=Path, help="Path to nanoplot output .txt")

    return parser.parse_args()


def process_sylph_report(report, min_abundance=98):
    df = pd.read_csv(report, sep="\t")
    if float(df.iloc[0]["Sequence_abundance"]) >= min_abundance:
        return "PASS"
    else:
        return "FAIL"


def process_fastqc_report(report, criteria_file):
    with open(criteria_file) as j:
        pass_criteria = set(json.load(j))

    with open(report) as f:
        for line in f:
            fields = line.strip("\n").split('\t')
            if fields[1] in pass_criteria and fields[0] == "FAIL":
                return "FAIL"

    return "PASS"


def short_read_depth(fastq, min_depth, lower_assembly_length):
    opener = gzip.open if str(fastq).endswith(".gz") else open
    bases = 0
    with opener(fastq, "rt") as f:
        for i, line in enumerate(f):
            if i % 4 == 1:
                bases += len(line)

    if (bases * 2) / lower_assembly_length >= min_depth:
        return("PASS")
    else:
        return("FAIL")


def process_nanoplot_report(nanoplot_out, min_depth, lower_assembly_length):
    with open(nanoplot_out) as f:
        for line in f.read().split('\n'):
            if line.startswith("Total bases:"):
                bases = line.replace(" ", "").split(":")[1]
                bases = float(bases.replace(",", ""))
                if bases >= min_depth * lower_assembly_length:
                    return('PASS')
                else:
                    return('FAIL')
                break


def main():
    args = parse_args()

    sylph_status = process_sylph_report(args.sylph_profile)
    if args.mode == "short":
        fastqc_r1_status = process_fastqc_report(args.fastqc_r1, args.pass_criteria_json)
        fastqc_r2_status = process_fastqc_report(args.fastqc_r2, args.pass_criteria_json)
        short_depth_status = short_read_depth(args.sample_fq, args.min_depth, args.lower_assembly_length)
    else:
        nanoplot_status = process_nanoplot_report(args.nanoplot_out, args.min_depth, args.lower_assembly_length)

    rows = {"ID": args.id}
    rows["sylph"] = sylph_status
    if args.mode == "short":
        rows["fastqc_r1"] = fastqc_r1_status
        rows["fastqc_r2"] = fastqc_r2_status
        rows["depth"] = short_depth_status
    else:
        rows["nanoplot"] = nanoplot_status

    status = "PASS"
    failed = []
    for key, value in rows.items():
        if value == "FAIL":
            failed.append(key)
            status = "FAIL"

    rows["QC Status"] = status
    rows["QC Failed Fields"] = ", ".join(failed)
    print(status)

    df = pd.DataFrame([rows])
    df = df[["ID", "QC Status", "QC Failed Fields"]]
    df.to_csv(f"{args.id}_{args.mode}_fq_report.tsv", sep="\t", index=False)

if __name__ == "__main__":
    main()
    