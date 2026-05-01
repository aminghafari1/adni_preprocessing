#!/bin/bash

#!/bin/bash

set -euo pipefail
source "$PROJECT_ROOT/config.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"

acq_file="$prep_fmap/acqparams.txt"
python3 "$SCRIPT_DIR/prepare_acq_fmap.py" \
    "$inputs_dir/PA.json" \
    "$inputs_dir/AP.json" \
    "$acq_file" 

echo "Now running FSL's topup for susceptibility distortion correction... "
fslmaths "$inputs_dir/AP.nii.gz" -Tmean "$prep_fmap/AP_mean.nii.gz"
fslmaths "$inputs_dir/PA.nii.gz" -Tmean "$prep_fmap/PA_mean.nii.gz"

fslmerge -t "$prep_fmap/b0_all.nii.gz" "$prep_fmap/PA_mean.nii.gz" "$prep_fmap/AP_mean.nii.gz"
echo "topup"
topup --imain="$prep_fmap/b0_all.nii.gz" --datain="$acq_file" --config=b02b0.cnf --out="$prep_fmap/topup_results" --iout="$prep_fmap/corrected_b0.nii.gz"
echo "Now applying the topup correction to the functional data using FSL's applytopup... "
applytopup --imain="$prep_func/fmri_mc.nii.gz" --inindex=1 --datain="$acq_file" --topup="$prep_fmap/topup_results" --out="$prep_func/fmri_sc.nii.gz" --method=jac