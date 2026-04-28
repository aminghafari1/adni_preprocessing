#! /bin/bash

set -euo pipefail
source "$(dirname "$0")/config.sh" 
echo "Processing subject: $sub_code"
mkdir -p "$adni_preprocessing"
mkdir -p "$prep_dir"
mkdir -p "$prep_fmap"
mkdir -p "$prep_func"
mkdir -p "$prep_transforms"
mkdir -p "$qc_dir"

echo "Running synthstrip for brain extraction on the magnitude images... "
~/synthstrip-singularity -i "$inputs_dir/mag1.nii.gz" -o "$prep_fmap/mag1_brain.nii.gz" 
~/synthstrip-singularity -i "$inputs_dir/mag2.nii.gz" -o "$prep_fmap/mag2_brain.nii.gz" 

echo "Getting slice timing information from the json file and saving it in a text file for FSL... "
python3 get_slice_timing_file.py \
    "$inputs_dir/fmri_input.json" \
    "$inputs_dir/fmri_input.nii.gz" \
    "$prep_func/slicetiming_fsl.txt"

echo "Now correcting for slice timing using FSL's slicetimer... "

TR=$(python3 -c "import json; print(json.load(open('$inputs_dir/fmri_input.json'))['RepetitionTime'])")

slicetimer \
    -i "$inputs_dir/fmri_input.nii.gz" \
    -o "$prep_func/fmri_stc.nii.gz" \
    -r "$TR" \
    --tcustom="$prep_func/slicetiming_fsl.txt"

echo "Now correcting for motion using FSL's mcflirt... "
mcflirt -in "$prep_func/fmri_stc.nii.gz" -out "$prep_func/fmri_mc.nii.gz" -plots  -meanvol

confounds_dir="$prep_func/confounds"
mkdir -p "$confounds_dir"
python3 compute_fd.py \
    "$prep_func/fmri_mc.nii.gz.par" \
    "$confounds_dir/framewise.txt"

echo "Now computing dvars using FSL's fsl_motion_outliers... "
fsl_motion_outliers -i "$prep_func/fmri_mc.nii.gz" -s "$confounds_dir/dvars_values.txt" -o "$confounds_dir/dvars_volumes.txt"   --nomoco
## --nomoco because it is already done.

echo "Getting mean of the fMRI time series for registration... "
fslmaths "$prep_func/fmri_mc.nii.gz" -Tmean "$prep_func/fmri_mc_avg.nii.gz"
~/synthstrip-singularity -i "$prep_func/fmri_mc_avg.nii.gz" -o "$prep_func/fmri_mc_avg_brain.nii.gz" -m "$prep_func/fmri_mc_avg_brain_mask.nii.gz"

echo "Preparing the fieldmap using FSL's fsl_prepare_fieldmap... "
fsl_prepare_fieldmap SIEMENS "$inputs_dir/phase_difference.nii.gz" "$prep_fmap/mag1_brain.nii.gz" "$prep_fmap/fieldmap_rads.nii.gz" 2.46
## This 2.46 is the difference between the two TEs and should be automated later by reading the json files.

echo "We need to take the field map to the same space as EPI, first, smooth using fugure."
fugue --loadfmap="$prep_fmap/fieldmap_rads.nii.gz" -s 2.0 --savefmap="$prep_fmap/fieldmap_smooth.nii.gz"

echo "Warping the magnitude image using the fieldmap."
fugue -i "$prep_fmap/mag1_brain.nii.gz" --dwell=0.000570006 --unwarpdir=y- --loadfmap="$prep_fmap/fieldmap_smooth.nii.gz" -u "$prep_fmap/mag1_brain_warped.nii.gz"

echo "Registering the unwarped magnitude image to EPI image"
flirt -in "$prep_fmap/mag1_brain_warped.nii.gz" -ref "$prep_func/fmri_mc_avg_brain.nii.gz" -out "$prep_fmap/mag1_to_epi.nii.gz" -omat "$prep_transforms/mag1_to_epi.mat" -dof 6 -cost normmi

echo "Taking the field map to the EPI space."
flirt -in "$prep_fmap/fieldmap_smooth.nii.gz" -ref "$prep_func/fmri_mc_avg_brain.nii.gz" -applyxfm -init "$prep_transforms/mag1_to_epi.mat" -out "$prep_fmap/fieldmap_epi.nii.gz"

echo "Applying the fieldmap to unwarp the fMRI average brain image."
fugue -i "$prep_func/fmri_mc_avg_brain.nii.gz" --dwell=0.000570006 --unwarpdir=y --loadfmap="$prep_fmap/fieldmap_epi.nii.gz" -u "$prep_func/fmri_sc_avg_brain.nii.gz"

echo "Now applying the same unwarping to the entire fMRI time series... "
fugue -i "$prep_func/fmri_mc.nii.gz" --dwell=0.000570006 --unwarpdir=y --loadfmap="$prep_fmap/fieldmap_epi.nii.gz" -u "$prep_func/fmri_sc.nii.gz"
