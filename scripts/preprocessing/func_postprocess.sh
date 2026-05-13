#!/bin/bash
set -euo pipefail
source "$PROJECT_ROOT/config.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Computing aCompCor regressors (top 5 PCs from combined WM+CSF mask)..."
python3 "$SCRIPT_DIR/compute_acompcor.py" \
    "$prep_func/fmri_sc_MNI.nii.gz" \
    "$prep_anat/MNI_bin_WM.nii.gz" \
    "$prep_anat/MNI_bin_CSF.nii.gz" \
    "$confounds_dir/acompcor_PCs.txt" \
    --n-components 5

echo "Creating confounds matrix"
paste "$prep_func/fmri_mc.nii.gz.par" \
      "$confounds_dir/acompcor_PCs.txt" \
       > "$confounds_dir/confounds_matrix_init.txt"

ncols=$(python3 "$SCRIPT_DIR/build_confounds.py" \
    "$confounds_dir/confounds_matrix_init.txt" \
    "$confounds_dir/confounds_matrix_final.txt" \
    --motion-model "$MOTION_MODEL")

echo "Nuisance regression using FSL's 3dTproject..."
3dTproject \
    -input "$prep_func/fmri_sc_MNI.nii.gz" \
    -prefix "$prep_func/fmri_MNI_nuireg.nii.gz" \
    -ort "$confounds_dir/confounds_matrix_final.txt" \
    -polort 2 \
    -mask "$MNIMASK" -overwrite

echo "Spatial smoothing."
sigma=$(echo "$SMOOTH_FWHM / 2.355" | bc -l)

printf "Spatial smoothing with FWHM = %.2f mm (sigma = %.2f voxels)...\n" "$SMOOTH_FWHM" "$sigma"
fslmaths "$prep_func/fmri_MNI_nuireg.nii.gz" -s "$sigma" "$prep_func/fmri_MNI_smoothed.nii.gz"

TR=$(python3 -c "import json; print(json.load(open('$inputs_dir/fmri_input.json'))['RepetitionTime'])")
HP_SIGMA=$(echo "1 / (2 * 3.14159 * $HP_FREQ * $TR)" | bc -l)
LP_SIGMA=$(echo "1 / (2 * 3.14159 * $LP_FREQ * $TR)" | bc -l)

echo "Applying bandpass filter with high-pass cutoff $HP_FREQ Hz and low-pass cutoff $LP_FREQ Hz..."
fslmaths "$prep_func/fmri_MNI_smoothed.nii.gz" \
    -bptf $HP_SIGMA $LP_SIGMA \
    "$prep_func/fmri_MNI_preprocessed.nii.gz"

