#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/config.sh"

raw_MNI=${prep_func}/fmri_input_MNI.nii.gz
processed_MNI=${prep_func}/fmri_MNI_preprocessed.nii.gz
dvars=${confounds_dir}/dvars_values.txt
fd=${confounds_dir}/framewise.txt

echo "Generating carpet plots for raw and preprocessed data in MNI space, and checking their alignment with motion and dvars outliers."
python3 compute_carpet.py $raw_MNI $processed_MNI $fd $dvars $qc_dir $fd_threshold $dvars_z