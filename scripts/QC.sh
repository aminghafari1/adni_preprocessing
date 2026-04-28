#! /bin/bash

set -euo pipefail
source "$(dirname "$0")/config.sh" 
mkdir -p "$qc_dir"

echo "QC part 1, calculate tSNR of the smoothed scan and compare it across subjects and regions"
./tsnr_QC.sh ${prep_func}/fmri_MNI_smoothed.nii.gz ${qc_dir}/tsnr_MNI.nii.gz $MNIMASK

echo "QC part 2, registration from T1 to MNI space using dice coefficient for gray matter and white matter masks."
./registration_QC.sh

echo "QC part 3, Let's take a look at the connectomes and their distributions."
./connectome_QC.sh

echo "QC part 4, let's get carpet plots of raw and preprocessed data in MNI space, and check their alignment with motion and dvars outliers."
./carpet_QC.sh

