#! /bin/bash

set -euo pipefail
source "$PROJECT_ROOT/config.sh"
echo "Processing subject: $sub_code"
mkdir -p "$adni_preprocessing"
mkdir -p "$prep_dir"
mkdir -p "$prep_fmap"
mkdir -p "$prep_func"
mkdir -p "$prep_transforms"
mkdir -p "$qc_dir"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TR=$(python3 -c "import json; print(json.load(open('$inputs_dir/fmri_input.json'))['RepetitionTime'])")

echo "Getting slice timing information from the json file and saving it in a text file for FSL... "
python3 "$SCRIPT_DIR/get_slice_timing_file.py" \
    "$inputs_dir/fmri_input.json" \
    "$TR" \
    "$prep_func/slicetiming_fsl.txt"

echo "Now correcting for slice timing using FSL's slicetimer... "
slicetimer \
    -i "$inputs_dir/fmri_input.nii.gz" \
    -o "$prep_func/fmri_stc.nii.gz" \
    -r "$TR" \
    --tcustom="$prep_func/slicetiming_fsl.txt"

echo "Now correcting for motion using FSL's mcflirt... "
mcflirt -in "$prep_func/fmri_stc.nii.gz" -out "$prep_func/fmri_mc.nii.gz" -plots  -meanvol

confounds_dir="$prep_func/confounds"
mkdir -p "$confounds_dir"
python3 "$SCRIPT_DIR/compute_fd.py" \
    "$prep_func/fmri_mc.nii.gz.par" \
    "$confounds_dir/framewise.txt"

echo "Now computing dvars using FSL's fsl_motion_outliers... "
fsl_motion_outliers -i "$prep_func/fmri_mc.nii.gz" -s "$confounds_dir/dvars_values.txt" -o "$confounds_dir/dvars_volumes.txt"   --nomoco
## --nomoco because it is already done.
