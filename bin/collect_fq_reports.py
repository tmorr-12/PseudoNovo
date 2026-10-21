#!/usr/bin/env python3

import argparse
import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser(description="Combine fastq qc reports into one")
    parser.add_argument("--id", type=str, required=True, help="ID of sample")
    parser.add_argument("--mode", type=str, required=True, choices=["short", "long"], help="short or long reads")
    parser.add_argument("--fastqc_r1", choices=["PASS", "FAIL", "na"], help="sample fastqc PASS/FAIL")
    parser.add_argument("--fastqc_r2", choices=["PASS", "FAIL", "na"], help="sample fastqc PASS/FAIL")
    parser.add_argument("--fastp", choices=["PASS", "FAIL", "na"], help="sample fastp PASS/FAIL")
    parser.add_argument("--sylph", choices=["PASS", "FAIL", "na"], help="sample sylph PASS/FAIL")
    parser.add_argument("--nanoplot", choices=["PASS", "FAIL", "na"], help="sample nanoplot PASS/FAIL")
    return parser.parse_args()


def main():
    args = parse_args()

    rows = {"ID": args.id}
    if args.fastqc_r1 and args.fastqc_r1 != "na":
        rows["fastqc_r1"] = args.fastqc_r1
    if args.fastqc_r2 and args.fastqc_r2 != "na":
        rows["fastqc_r2"] = args.fastqc_r2
    if args.fastp and args.fastp != "na":
        rows["fastp"] = args.fastp
    if args.sylph and args.sylph != "na":
        rows["sylph"] = args.sylph
    if args.nanoplot and args.nanoplot != "na":
        rows["nanoplot"] = args.nanoplot

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
    