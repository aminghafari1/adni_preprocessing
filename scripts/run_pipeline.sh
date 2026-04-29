#!/usr/bin/env bash
set -euo pipefail

# always run from repo root (important)

# Check input argument
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <sub_code>"
    echo "Example: $0 002_0413"
    exit 1
fi

sub_code="$1"
export sub_code

cd "$(dirname "$0")"
source ./config.sh

echo "🚀 Starting full pipeline..."

echo "➡️ Step 0: Convert dicoms to nifti"
#bash "$PROJECT_ROOT/preprocessing/dicom_2_niftii.sh"

echo "➡️ Step 1: Starter"
#bash "$PROJECT_ROOT/preprocessing/prep_starter.sh"

echo "➡️ Step 2: Anatomical preprocessing"
#bash "$PROJECT_ROOT/preprocessing/prep_anat.sh"

echo "➡️ Step 3: fMRI → MNI registration"
#bash "$PROJECT_ROOT/preprocessing/fmri_to_mni_registration.sh"

echo "➡️ Step 4: Smoothing"
#bash "$PROJECT_ROOT/preprocessing/spatial_smoothing.sh"

echo "➡️ Step 5: Nuisance regression"
#bash "$PROJECT_ROOT/preprocessing/nuisance_regression_bp_filtering.sh"

echo "✅ Pipeline finished successfully!"
echo "Let's do quality control."
bash "$PROJECT_ROOT/QC.sh"