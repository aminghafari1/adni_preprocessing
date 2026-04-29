#!/bin/bash
set -euo pipefail
source "$PROJECT_ROOT/config.sh"

echo "Calculating different tissues signals for regression."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for tissue in WM GM CSF; do
    fslmeants \
        -i "$prep_func/fmri_MNI_smoothed.nii.gz" \
        -m "$prep_anat/MNI_${tissue}.nii.gz" \
        -o "$confounds_dir/MNI_${tissue}.txt"
done

echo "Extracting the global signal."
fslmeants \
    -i "$prep_func/fmri_MNI_smoothed.nii.gz" \
    -m "$MNIMASK" \
    -o "$confounds_dir/MNI_global_signal.txt"

  
echo "Creating framewise displacement regressors with threshold $fd_threshold..."
python3 "$SCRIPT_DIR/one_hot_fd.py" "$confounds_dir/framewise.txt" "$confounds_dir/dvars_values.txt"  \
"$confounds_dir/fd_regressors.txt" $fd_threshold $dvars_z

echo "Creating confounds matrix"
paste "$prep_func/fmri_mc.nii.gz.par" \
      "$confounds_dir/MNI_WM.txt" "$confounds_dir/MNI_CSF.txt" \
       > "$confounds_dir/confounds_matrix_init.txt"

ncols=$(python3 "$SCRIPT_DIR/build_confounds.py" \
    "$confounds_dir/confounds_matrix_init.txt" \
    "$confounds_dir/fd_regressors.txt" \
    "$confounds_dir/confounds_matrix_final.txt")


3dTproject \
    -input "$prep_func/fmri_MNI_smoothed.nii.gz" \
    -prefix "$prep_func/fmri_MNI_preprocessed.nii.gz" \
    -ort "$confounds_dir/confounds_matrix_final.txt" \
    -polort 2 \
    -mask "$MNIMASK" -overwrite
