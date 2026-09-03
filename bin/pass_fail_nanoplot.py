#!/usr/bin/env python3

import sys

if __name__ == "__main__":
    ID = sys.argv[1]
    nanoplot_out = sys.argv[2]
    min_depth = int(sys.argv[3])
    lower_assembly_length = int(sys.argv[4])

    with open(nanoplot_out) as f:
        for line in f.read().split('\n'):
            if line.startswith("Total bases:"):
                bases = line.replace(" ", "").split(":")[1]
                bases = float(bases.replace(",", ""))
                if bases >= min_depth * lower_assembly_length:
                    print('PASS')
                else:
                    print('FAIL')
                break