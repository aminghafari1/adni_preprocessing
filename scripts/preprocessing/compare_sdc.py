"""
Compare two SDC-corrected mean EPI images against a T1 using normalized mutual
information. Resamples both candidates into T1 space via NIfTI affines (no
registration — fast, sufficient for discriminating PE direction).

Usage:
    python3 compare_sdc.py <fwd.nii.gz> <fwd_dir> <rev.nii.gz> <rev_dir> <T1.nii.gz>

Prints the winning unwarp direction to stdout.
"""
import sys
import numpy as np
import nibabel as nib
from nibabel.processing import resample_from_to


def nmi(a, b, bins=64):
    mask = (a > 0) & (b > 0)
    x, y = a[mask].ravel(), b[mask].ravel()
    joint, _, _ = np.histogram2d(x, y, bins=bins)
    joint /= joint.sum()
    px, py = joint.sum(axis=1), joint.sum(axis=0)

    def entropy(p):
        p = p[p > 0]
        return -np.sum(p * np.log(p))

    denom = entropy(joint)
    if denom == 0:
        return 0.0
    return (entropy(px) + entropy(py)) / denom


fwd_path, fwd_dir, rev_path, rev_dir, t1_path = sys.argv[1:]

t1 = nib.load(t1_path)
t1_data = t1.get_fdata()

fwd_data = resample_from_to(nib.load(fwd_path), t1, order=1).get_fdata()
rev_data = resample_from_to(nib.load(rev_path), t1, order=1).get_fdata()

nmi_fwd = nmi(fwd_data, t1_data)
nmi_rev = nmi(rev_data, t1_data)

print(f"NMI fwd ({fwd_dir}): {nmi_fwd:.4f}  rev ({rev_dir}): {nmi_rev:.4f}", file=sys.stderr)
print(fwd_dir if nmi_fwd >= nmi_rev else rev_dir)
