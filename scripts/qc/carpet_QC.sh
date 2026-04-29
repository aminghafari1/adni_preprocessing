#!/bin/bash

set -euo pipefail
source "$PROJECT_ROOT/config.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
raw_MNI=${prep_func}/fmri_input_MNI.nii.gz
processed_MNI=${prep_func}/fmri_MNI_preprocessed.nii.gz
dvars=${confounds_dir}/dvars_values.txt
fd=${confounds_dir}/framewise.txt

echo "Generating carpet plots for raw and preprocessed data in MNI space, and checking their alignment with motion and dvars outliers."
output=$(python3 "$SCRIPT_DIR/compute_carpet.py" $raw_MNI $processed_MNI $fd $dvars $qc_dir $fd_threshold $dvars_z)

max_fd=$(echo "$output" | grep "Maximum_FD=" | cut -d= -f2)
high_fd_percent=$(echo "$output" | grep "HIGH_FD_PERCENT=" | cut -d= -f2)

export max_fd
export high_fd_percent