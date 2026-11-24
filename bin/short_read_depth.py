#!/usr/bin/env python3

import sys
import gzip

if __name__ == "__main__":
    R1 = sys.argv[1]
    genome_size = int(sys.argv[2])

    opener = gzip.open if R1.endswith(".gz") else open
    bases = 0
    with opener(R1, "rt") as f:
        for i, line in enumerate(f):
            if i % 4 == 1:
                bases += len(line)

    if (bases * 2) / genome_size >= 30:
        print("PASS")
    else:
        print("FAIL")
