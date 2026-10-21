#!/usr/bin/env bash

set -euo pipefail

ID=""
MODE=""
COLLECT_FQ_REPORTS=""
PASS_FAIL_FASTQC=""
PASS_FAIL_FASTP=""
PASS_FAIL_NANOPLOT=""
SYLPH_PROFILE_TSV=""
FASTQC_R1_SUMMARY=""
FASTQC_R2_SUMMARY=""
FASTQC_PASS_CRITERIA=""
FASTP_JSON=""
NANOPLOT_OUT=""
MIN_DEPTH=""
LOWER_ASSEMBLY_LENGTH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --id)                     ID="$2"; shift 2 ;;
        --mode)                   MODE="$2"; shift 2 ;;
        --collect_fq_reports)     COLLECT_FQ_REPORTS="$2"; shift 2 ;;
        --pass_fail_fastqc)       PASS_FAIL_FASTQC="$2"; shift 2 ;;
        --pass_fail_fastp)        PASS_FAIL_FASTP="$2"; shift 2 ;;
        --pass_fail_nanoplot)     PASS_FAIL_NANOPLOT="$2"; shift 2 ;;
        --sylph_profile_tsv)      SYLPH_PROFILE_TSV="$2"; shift 2 ;;
        --fastqc_r1_summary)      FASTQC_R1_SUMMARY="$2"; shift 2 ;;
        --fastqc_r2_summary)      FASTQC_R2_SUMMARY="$2"; shift 2 ;;
        --fastqc_pass_criteria)   FASTQC_PASS_CRITERIA="$2"; shift 2 ;;
        --fastp_json)             FASTP_JSON="$2"; shift 2 ;;
        --nanoplot_out)           NANOPLOT_OUT="$2"; shift 2 ;;
        --min_depth)              MIN_DEPTH="$2"; shift 2 ;;
        --lower_assembly_length)  LOWER_ASSEMBLY_LENGTH="$2"; shift 2 ;;
        -*)  echo "Error: Unknown argument -> $1" >&2; exit 1 ;;
        *)   echo "Error: This script does not accept positional arguments" >&2; exit 1 ;;
    esac
done

fastqc_r1_status="na"
fastqc_r2_status="na"
fastp_status="na"
sylph_status="na"
nanoplot_status="na"

if [[ -n "$PASS_FAIL_FASTQC" ]]; then
    fastqc_r1_status=$("$PASS_FAIL_FASTQC" --summary_file "$FASTQC_R1_SUMMARY" --pass_criteria_json "$FASTQC_PASS_CRITERIA")
    fastqc_r2_status=$("$PASS_FAIL_FASTQC" --summary_file "$FASTQC_R2_SUMMARY" --pass_criteria_json "$FASTQC_PASS_CRITERIA")
fi

if [[ -n "$PASS_FAIL_FASTP" ]]; then
    fastp_status=$("$PASS_FAIL_FASTP" "$FASTP_JSON" "$MIN_DEPTH" "$LOWER_ASSEMBLY_LENGTH")
fi

if [[ -n "$SYLPH_PROFILE_TSV" ]]; then
    sylph_status=$(sed -n '2p' "$SYLPH_PROFILE_TSV" |
        awk -F'\t' '$4 > 98 {found=1} END {print (found ? "PASS" : "FAIL")}')
fi

if [[ -n "$PASS_FAIL_NANOPLOT" ]]; then
    nanoplot_status=$("$PASS_FAIL_NANOPLOT" "$NANOPLOT_OUT" "$MIN_DEPTH" "$LOWER_ASSEMBLY_LENGTH")
fi

${COLLECT_FQ_REPORTS} \
    --id ${ID} \
    --mode ${MODE} \
    --fastqc_r1 ${fastqc_r1_status} \
    --fastqc_r2 ${fastqc_r2_status} \
    --fastp ${fastp_status} \
    --sylph ${sylph_status} \
    --nanoplot ${nanoplot_status}
