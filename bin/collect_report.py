#!/usr/bin/env python3

# To add extra assembly qc steps, update the report_keep_columns.json config,
# then add the qc parameter to qc.config and supply as argument to this script,
# finally update the qc_row function to qc the column(s)

import argparse
from pathlib import Path
import json

import pandas as pd

class InvalidConfigError(Exception):
    pass

FASTA_EXT = {".fa", ".fasta", ".fa.gz", ".fasta.gz", ".fna", ".fna.gz"}


def parse_args():
    parser = argparse.ArgumentParser(description="Combine assembly reports into one")

    required = parser.add_argument_group("required args")
    required.add_argument("--id", type=str, required=True, help="ID of sample")
    required.add_argument("--reports", nargs="+", type=Path, required=True, help="List of paths pointing to assembly qc reports")
    required.add_argument("--config", type=Path, required=True, help="Path to 'report_keep_columns.json'")

    qc_fields = parser.add_argument_group("qc fields")
    qc_fields.add_argument("--target_size", type=int, required=True, help="Target genome size in bp")
    qc_fields.add_argument("--completeness", type=float, required=True, help="Threshold CheckM2 completeness score")
    qc_fields.add_argument("--contamination", type=float, required=True, help="Threshold CheckM2 contamination score")
    qc_fields.add_argument("--gc", type=float, required=True, help="Target genome GC content")

    return parser.parse_args()


def qc_row(row, args):
    """
    QC each row, find which fields pass and which fail:
        - Total assembly length: ±20% target genome size
        - GC content: ±10% target GC content
        - CheckM2 Completeness: At least 98% completeness (default)
        - CheckM2 Contamination: No more than 2% contamination (default)
    """
    failed = []

    # === genome size (quast total length) ===

    min_length = args.target_size * 0.8
    max_length = args.target_size * 1.2
    if not (min_length <= row["Total length"] <= max_length):
        failed.append("Total length")

    # === checkm2 completeness ===

    if row["Completeness"] < args.completeness:
        failed.append("Completeness")

    # === checkm2 contamination ===

    if row["Contamination"] > args.contamination:
        failed.append("Contamination")

    # === checkm2 GC content ===

    min_gc = args.gc * 0.9
    max_gc = args.gc * 1.1
    if not (min_gc <= row["GC_Content"] <= max_gc):
        failed.append("GC_Content")

    # === End ===

    if len(failed) == 0:
        status = "PASS"
    else:
        status = "FAIL"

    return status, ", ".join(failed)


def validate_config(config):
    valid_keys = {"tool", "id_col", "keep_columns"}
    keep_columns, id_columns = [], []
    with open(config) as f:
        c = json.load(f)
        for tool in c:
            for key, values in tool.items():
                if key not in valid_keys:
                    raise InvalidConfigError(f"Invalid reporting config -> {config}")
                if key == "keep_columns":
                    keep_columns += values
                if key == "id_col":
                    id_columns.append(values)
    return keep_columns, id_columns


def strip_fasta_ext(value):
    for ext in sorted(FASTA_EXT, key=len, reverse=True):
        if value.endswith(ext):
            return value[: -len(ext)]
    return value


def parse_report(report, keep_columns, id_columns):
    df = pd.read_csv(report, sep="\t")
    final_df = pd.DataFrame()

    for id_ in id_columns:
        if id_ in df.columns:
            final_df["ID"] = df[id_].astype(str).map(strip_fasta_ext)
            break

    for keep in keep_columns:
        if keep in df.columns:
            final_df[keep] = df[keep]

    return final_df


def main():
    args = parse_args()
    keep_columns, id_columns = validate_config(args.config)

    dfs = []
    for report in args.reports:
        dfs.append(parse_report(report, keep_columns, id_columns))

    merged_df = dfs[0]
    for df in dfs[1:]:
        merged_df = pd.merge(merged_df, df, on="ID", how="outer")

    merged_df[["QC Status", "QC Failed Fields"]] = merged_df.apply(
        lambda row: pd.Series(qc_row(row, args)), axis=1
    )

    merged_df = merged_df.drop(["Name", "FILE", "Assembly"], axis=1)

    # enforce report column order to match order of appearance in config file
    ordered_cols = [c for c in keep_columns if c in merged_df.columns and c != "ID"]
    extra_cols = [c for c in merged_df.columns if c not in ordered_cols and c != "ID"]
    merged_df = merged_df[["ID"] + ordered_cols + extra_cols]

    status = merged_df["QC Status"].iloc[0]
    print(status)

    merged_df.to_csv(f"{args.id}_report.tsv", sep='\t', index=None)


if __name__ == "__main__":
    main()
