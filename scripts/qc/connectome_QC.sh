#! /bin/bash

set -euo pipefail
source "$PROJECT_ROOT/config.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

raw_MNI=${prep_func}/fmri_input_MNI.nii.gz
processed_MNI=${prep_func}/fmri_MNI_preprocessed.nii.gz

python3 "$SCRIPT_DIR/compare_connectomes.py" $raw_MNI $processed_MNI $MNIPARCEL $qc_dir