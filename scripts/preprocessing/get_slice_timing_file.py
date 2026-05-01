#!/usr/bin/env python3

import json
import sys


def main():
    if len(sys.argv) != 4:
        print("Usage: python3 get_slice_timing_file.py <json_file> <TR> <output_txt>")
        sys.exit(1)

    json_file = sys.argv[1]
    tr = float(sys.argv[2])
    output_txt = sys.argv[3]

    with open(json_file, "r") as f:
        meta = json.load(f)

    if "SliceTiming" not in meta:
        raise KeyError("SliceTiming not found in JSON file.")

    slice_timing = meta["SliceTiming"]

    if not isinstance(slice_timing, list) or len(slice_timing) == 0:
        raise ValueError("SliceTiming exists but is empty or not a list.")

    if tr <= 0:
        raise ValueError(f"Invalid TR found: {tr}")

    converted = [(float(t) / tr) - 0.5 for t in slice_timing]

    with open(output_txt, "w") as f:
        for val in converted:
            f.write(f"{val:.8f}\n")

    print(f"Read {len(slice_timing)} slice timings from: {json_file}")
    print(f"TR used: {tr}")
    print(f"Saved converted timing file to: {output_txt}")


if __name__ == "__main__":
    main()