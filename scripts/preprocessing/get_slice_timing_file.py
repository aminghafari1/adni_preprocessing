#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path


def get_tr_from_fslinfo(nifti_file):
    """Read TR (pixdim4) from fslinfo output."""
    result = subprocess.run(
        ["fslinfo", nifti_file],
        capture_output=True,
        text=True,
        check=True
    )

    for line in result.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 2 and parts[0] == "pixdim4":
            return float(parts[1])

    raise RuntimeError("Could not find pixdim4 (TR) in fslinfo output.")


def main():
    if len(sys.argv) != 4:
        print("Usage: python3 make_slice_timing_file.py <json_file> <nifti_file> <output_txt>")
        sys.exit(1)

    json_file = sys.argv[1]
    nifti_file = sys.argv[2]
    output_txt = sys.argv[3]

    # Read JSON
    with open(json_file, "r") as f:
        meta = json.load(f)

    if "SliceTiming" not in meta:
        raise KeyError("SliceTiming not found in JSON file.")

    slice_timing = meta["SliceTiming"]

    if not isinstance(slice_timing, list) or len(slice_timing) == 0:
        raise ValueError("SliceTiming exists but is empty or not a list.")

    # Read TR from fslinfo
    tr = get_tr_from_fslinfo(nifti_file)

    if tr <= 0:
        raise ValueError(f"Invalid TR found: {tr}")

    # Convert to FSL slicetimer custom timing format
    converted = [(float(t) / tr) - 0.5 for t in slice_timing]

    # Save output
    with open(output_txt, "w") as f:
        for val in converted:
            f.write(f"{val:.8f}\n")

    print(f"Read {len(slice_timing)} slice timings from: {json_file}")
    print(f"TR from fslinfo: {tr}")
    print(f"Saved converted timing file to: {output_txt}")


if __name__ == "__main__":
    main()