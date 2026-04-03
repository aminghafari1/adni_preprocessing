#!/usr/bin/env bash
set -euo pipefail

# always run from repo root (important)
cd "$(dirname "$0")"

echo "🚀 Starting full pipeline..."

echo "➡️ Step 0: Convert dicoms to nifti"
./dicom_2_niftii.sh

echo "➡️ Step 1: Starter"
./prep_starter.sh

echo "➡️ Step 2: Anatomical preprocessing"
./prep_anat.sh

echo "➡️ Step 3: fMRI → MNI registration"
./fmri_to_mni_registration.sh

echo "✅ Pipeline finished successfully!"