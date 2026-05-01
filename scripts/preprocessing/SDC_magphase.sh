#!/bin/bash

set -euo pipefail
source "$PROJECT_ROOT/config.sh"

echo "Running synthstrip for brain extraction on the magnitude images... "
~/synthstrip-singularity -i "$inputs_dir/mag1.nii.gz" -o "$prep_fmap/mag1_brain.nii.gz" 
~/synthstrip-singularity -i "$inputs_dir/mag2.nii.gz" -o "$prep_fmap/mag2_brain.nii.gz" 

echo "Getting mean of the fMRI time series for registration... "
fslmaths "$prep_func/fmri_mc.nii.gz" -Tmean "$prep_func/fmri_mc_avg.nii.gz"
~/synthstrip-singularity -i "$prep_func/fmri_mc_avg.nii.gz" -o "$prep_func/fmri_mc_avg_brain.nii.gz" -m "$prep_func/fmri_mc_avg_brain_mask.nii.gz"

echo "Get delta TE in milliseconds from the json file... "
DELTA_TE=$(python3 -c "
import json
with open('$inputs_dir/phase_difference.json') as f:
    meta = json.load(f)

te1 = float(meta['EchoTime1'])
te2 = float(meta['EchoTime2'])

print(abs(te2 - te1) * 1000)
")

echo "Preparing the fieldmap using FSL's fsl_prepare_fieldmap... "
fsl_prepare_fieldmap SIEMENS "$inputs_dir/phase_difference.nii.gz" "$prep_fmap/mag1_brain.nii.gz" "$prep_fmap/fieldmap_rads.nii.gz" $DELTA_TE
## This 2.46 is the difference between the two TEs and should be automated later by reading the json files.

echo "We need to take the field map to the same space as EPI, first, smooth using fugue."
fugue --loadfmap="$prep_fmap/fieldmap_rads.nii.gz" -s $fieldmap_smoothing_fwhm --savefmap="$prep_fmap/fieldmap_smooth.nii.gz"

dwell=$(python3 -c "import json; print(json.load(open('$inputs_dir/fmri_input.json'))['EffectiveEchoSpacing'])")

echo "Warping the magnitude image using the fieldmap."
fugue -i "$prep_fmap/mag1_brain.nii.gz" --dwell="$dwell" --unwarpdir=y- --loadfmap="$prep_fmap/fieldmap_smooth.nii.gz" -u "$prep_fmap/mag1_brain_warped.nii.gz"

echo "Registering the unwarped magnitude image to EPI image"
flirt -in "$prep_fmap/mag1_brain_warped.nii.gz" -ref "$prep_func/fmri_mc_avg_brain.nii.gz" -out "$prep_fmap/mag1_to_epi.nii.gz" -omat "$prep_transforms/mag1_to_epi.mat" -dof 6 -cost normmi

echo "Taking the field map to the EPI space."
flirt -in "$prep_fmap/fieldmap_smooth.nii.gz" -ref "$prep_func/fmri_mc_avg_brain.nii.gz" -applyxfm -init "$prep_transforms/mag1_to_epi.mat" -out "$prep_fmap/fieldmap_epi.nii.gz"

echo "Applying the fieldmap to unwarp the fMRI average brain image."
fugue -i "$prep_func/fmri_mc_avg_brain.nii.gz" --dwell="$dwell" --unwarpdir=y --loadfmap="$prep_fmap/fieldmap_epi.nii.gz" -u "$prep_func/fmri_sc_avg_brain.nii.gz"

echo "Now applying the same unwarping to the entire fMRI time series... "
fugue -i "$prep_func/fmri_mc.nii.gz" --dwell="$dwell" --unwarpdir=y --loadfmap="$prep_fmap/fieldmap_epi.nii.gz" -u "$prep_func/fmri_sc.nii.gz"