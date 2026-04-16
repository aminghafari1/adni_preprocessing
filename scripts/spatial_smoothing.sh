#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/config.sh"

func_mni="$prep_func/fmri_sc_MNI.nii.gz"

sigma=$(echo "$SMOOTH_FWHM / 2.355" | bc -l)

printf "Spatial smoothing with FWHM = %.2f mm (sigma = %.2f voxels)...\n" "$SMOOTH_FWHM" "$sigma"
fslmaths "$func_mni" -s "$sigma" "$prep_func/fmri_MNI_smoothed.nii.gz"