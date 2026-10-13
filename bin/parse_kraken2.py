#!/usr/bin/env python3

import sys
import re
import pandas as pd

if __name__ == "__main__":
    report = sys.argv[1]
    df = pd.read_csv(report, sep="\t", header=None)
    human = df[df[5].str.strip() == "Homo sapiens"]
    status = "PASS"
    for p in human[0]:
        if p >= 0.5:
            status = "FAIL"
            break
    print(status)
