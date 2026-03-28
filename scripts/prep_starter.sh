#! /bin/bash
sub_dir="/home/aghaffari/adni/002_1261"
fmri_dir="/home/aghaffari/adni/002_1261/func/2019-05-01_12_14_22.0/I1270025"  ## Automate after getting some more subjects
phase_dir="/home/aghaffari/adni/002_1261/fmap/2019-05-01_12_14_22.0/I1270031"
mag1_dir="/home/aghaffari/adni/002_1261/fmap/2019-05-01_12_14_22.0/I1270026"
mag2_dir="/home/aghaffari/adni/002_1261/fmap/2019-05-01_12_14_22.0/I1270032"

mkdir -p "$sub_dir/temp"
temp_dir="$sub_dir/temp"
if [ ! -d "$sub_dir/compressed_inputs" ]; then
        mkdir -p "$sub_dir/compressed_inputs"
fi
inputs_dir="$sub_dir/compressed_inputs"


echo "Converting fMRI dicom files to nifti files... "
~/dcmniix/dcm2niix -z y -o "$temp_dir" "$fmri_dir"
mv "$temp_dir"/*.nii.gz "$inputs_dir/fmri_input.nii.gz"
mv "$temp_dir"/*.json "$inputs_dir/fmri_input.json"
rm -rf "$temp_dir"/*

echo "Converting phase dicom files to nifti files... "
~/dcmniix/dcm2niix -z y -o "$temp_dir" "$phase_dir"
mv "$temp_dir"/*.nii.gz "$inputs_dir/phase_difference.nii.gz"
mv "$temp_dir"/*.json "$inputs_dir/phase_difference.json"
rm -rf "$temp_dir"/*

echo "Converting magnitude 1 dicom files to nifti files... "
~/dcmniix/dcm2niix -z y -o "$temp_dir" "$mag1_dir"
mv "$temp_dir"/*.nii.gz "$inputs_dir/mag1.nii.gz"
mv "$temp_dir"/*.json "$inputs_dir/mag1.json"
rm -rf "$temp_dir"/*

echo "Converting magnitude 2 dicom files to nifti files... "
~/dcmniix/dcm2niix -z y -o "$temp_dir" "$mag2_dir"
mv "$temp_dir"/*.nii.gz "$inputs_dir/mag2.nii.gz"
mv "$temp_dir"/*.json "$inputs_dir/mag2.json"
rm -rf "$temp_dir"/*

echo "Running synthstrip for brain extraction on the magnitude images... "
~/synthstrip-singularity -i "$inputs_dir/mag1.nii.gz" -o "$inputs_dir/mag1_brain.nii.gz" -m "$inputs_dir/mag1_brain_mask.nii.gz"
~/synthstrip-singularity -i "$inputs_dir/mag2.nii.gz" -o "$inputs_dir/mag2_brain.nii.gz" -m "$inputs_dir/mag2_brain_mask.nii.gz"

echo "Getting slice timing information from the json file and saving it in a text file for FSL... "
python3 get_slice_timing_file.py \
    "$inputs_dir/fmri_input.json" \
    "$inputs_dir/fmri_input.nii.gz" \
    "$inputs_dir/slicetiming_fsl.txt"

echo "Now correcting for slice timing using FSL's slicetimer... "
slicetimer \
    -i "$inputs_dir/fmri_input.nii.gz" \
    -o "$inputs_dir/fmri_stc.nii.gz" \
    -r "$(fslinfo "$inputs_dir/fmri_input.nii.gz" | awk '/^pixdim4/ {print $2}')" \
    --tcustom="$inputs_dir/slicetiming_fsl.txt"




echo "Now correcting for motion using FSL's mcflirt... "
mcflirt -in "$inputs_dir/fmri_stc.nii.gz" -out "$inputs_dir/fmri_mc.nii.gz" -plots  -meanvol

python3 compute_fd.py \
    "$inputs_dir/fmri_mc.nii.gz.par" \
    "$inputs_dir/framewise.txt"

echo "Now computing dvars using FSL's fsl_motion_outliers... "
fsl_motion_outliers -i "$inputs_dir/fmri_mc.nii.gz" -s "$inputs_dir/dvars_values.txt" -o "$inputs_dir/dvars_volumes.txt"   --nomoco
## --nomoco because it is already done.


echo "Getting mean of the fMRI time series for registration... "
fslmaths "$inputs_dir/fmri_mc.nii.gz" -Tmean "$inputs_dir/fmri_avg.nii.gz"
~/synthstrip-singularity -i "$inputs_dir/fmri_avg.nii.gz" -o "$inputs_dir/fmri_avg_brain.nii.gz" -m "$inputs_dir/fmri_avg_brain_mask.nii.gz"

echo "Preparing the fieldmap using FSL's fsl_prepare_fieldmap... "
fsl_prepare_fieldmap SIEMENS "$inputs_dir/phase_difference.nii.gz" "$inputs_dir/mag1_brain.nii.gz" "$inputs_dir/fieldmap_rads.nii.gz" 2.46
## This 2.46 is the difference between the two TEs and should be automated later by reading the json files.

echo "We need to take the field map to the same space as EPI, first, smooth using fugure."
fugue --loadfmap="$inputs_dir/fieldmap_rads.nii.gz" -s 2.0 --savefmap="$inputs_dir/fieldmap_smooth.nii.gz"

echo "Warping the magnitude image using the fieldmap."
fugue -i "$inputs_dir/mag1_brain.nii.gz" --dwell=0.000570006 --unwarpdir=y- --loadfmap="$inputs_dir/fieldmap_smooth.nii.gz" -u "$inputs_dir/mag1_brain_warped.nii.gz"

echo "Registering the unwarped magnitude image to EPI image"
flirt -in "$inputs_dir/mag1_brain_warped.nii.gz" -ref "$inputs_dir/fmri_avg_brain.nii.gz" -out "$inputs_dir/mag1_to_epi.nii.gz" -omat "$inputs_dir/mag1_to_epi.mat" -dof 6 -cost normmi

echo "Taking the field map to the EPI space."
flirt -in "$inputs_dir/fieldmap_smooth.nii.gz" -ref "$inputs_dir/fmri_avg_brain.nii.gz" -applyxfm -init "$inputs_dir/mag1_to_epi.mat" -out "$inputs_dir/fieldmap_epi.nii.gz"

echo "Applying the fieldmap to unwarp the fMRI average brain image."
fugue -i "$inputs_dir/fmri_avg_brain.nii.gz" --dwell=0.000570006 --unwarpdir=y --loadfmap="$inputs_dir/fieldmap_epi.nii.gz" -u "$inputs_dir/fmri_avg_brain_unwarped2.nii.gz"
