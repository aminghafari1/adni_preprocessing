#!/usr/bin/env python3
"""Compute aCompCor regressors: top N PCs from combined WM+CSF mask."""
import sys
import argparse
import numpy as np
import nibabel as nib


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("fmri", help="4D fMRI image in MNI space")
    parser.add_argument("wm_mask", help="WM binary mask in MNI space")
    parser.add_argument("csf_mask", help="CSF binary mask in MNI space")
    parser.add_argument("output", help="Output text file with PC time series (T x n_comp)")
    parser.add_argument("--n-components", type=int, default=5)
    args = parser.parse_args()

    fmri_data = nib.load(args.fmri).get_fdata()          # (X, Y, Z, T)
    wm_mask  = nib.load(args.wm_mask).get_fdata()  > 0.5
    csf_mask = nib.load(args.csf_mask).get_fdata() > 0.5
    mask = wm_mask | csf_mask

    n_vox = mask.sum()
    if n_vox == 0:
        print("ERROR: combined WM+CSF mask is empty", file=sys.stderr)
        sys.exit(1)

    T = fmri_data.shape[3]
    # voxels: (T, n_vox) — rows are time points, columns are voxels
    voxels = fmri_data[mask].T
    voxels -= voxels.mean(axis=0, keepdims=True)   # demean each voxel

    # Thin SVD on (T x n_vox): U columns are PCs in time domain
    n_comp = min(args.n_components, T, n_vox)
    U, _, _ = np.linalg.svd(voxels, full_matrices=False)
    PCs = U[:, :n_comp]   # (T, n_comp)

    np.savetxt(args.output, PCs, fmt="%.6f")
    print(f"aCompCor: {n_comp} PCs from {n_vox} WM+CSF voxels → {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
