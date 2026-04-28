#! /bin/bash

set -euo pipefail
source "$(dirname "$0")/config.sh"

raw_MNI=${prep_func}/fmri_input_MNI.nii.gz
processed_MNI=${prep_func}/fmri_MNI_preprocessed.nii.gz

python3 compare_connectomes.py $raw_MNI $processed_MNI $MNIPARCEL $qc_dir