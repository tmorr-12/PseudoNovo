#!/usr/bin/env python3

import sys
from collections import defaultdict

if __name__ == "__main__":
    ID = sys.argv[1]
    pre_report = sys.argv[2]
    post_report = sys.argv[3]

    class MalformedNanoStatsError(Exception):
        pass

    summary_dict = defaultdict(list)
    quality_dict = defaultdict(list)
    top_5_score_dict = defaultdict(list)
    top_5_length_dict = defaultdict(list)

    summary_header = "General summary"
    quality_header = "Number, percentage and megabases of reads above quality cutoffs"
    top_5_score_header = "Top 5 highest mean basecall quality scores and their read lengths"
    top_5_length_header = "Top 5 longest reads and their mean basecall quality score"

    for report in [pre_report, post_report]:
        active_dict = None
        with open(report) as f:
            file = f.read().strip().split('\n')
            for line in file:
                fields = line.split(":")

                if fields[0] == summary_header:
                    active_dict = summary_dict
                    continue
                elif fields[0] == quality_header:
                    active_dict = quality_dict
                    continue
                elif fields[0] == top_5_score_header:
                    active_dict = top_5_score_dict
                    continue
                elif fields[0] == top_5_length_header:
                    active_dict = top_5_length_dict
                    continue

                if len(fields) == 2:
                    active_dict[fields[0]].append(fields[1].lstrip())
                else:
                    raise MalformedNanoStatsError(f"Malformed NanoStats.txt file: {report}")    
                
    dict_list = [summary_dict, quality_dict, top_5_score_dict, top_5_length_dict]
    header_list = [summary_header, quality_header, top_5_score_header, top_5_length_header]

    # add delta values to summary_dict
    for key, val in summary_dict.items():
        before = float(val[0].replace(",", ""))
        after = float(val[1].replace(",", ""))
        summary_dict[key].append(f"{after - before:+.1f}")

    with open(f"{ID}_NanoStats_Summary.tsv", "w") as out_f:
        out_f.write(f"{ID}\tbefore\tafter\tdelta\n")
        for header, val_dict in zip(header_list, dict_list):
            out_f.write(f"\n=== {header} ===\n")
            for key, value in val_dict.items():
                line = "\t".join([key] + list(value))
                out_f.write(f"{line}\n")

