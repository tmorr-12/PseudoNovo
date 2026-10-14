#!/usr/bin/env python3

import json
import sys

if __name__ == "__main__":
    fastp_out = sys.argv[1]
    min_depth = int(sys.argv[2])
    lower_assembly_length = int(sys.argv[3])

    with open(fastp_out) as f:
        fastp = json.load(f)

    val = fastp["summary"]["after_filtering"]["total_bases"]

    if val >= min_depth * lower_assembly_length:
        print('PASS')
    else:
        print('FAIL')