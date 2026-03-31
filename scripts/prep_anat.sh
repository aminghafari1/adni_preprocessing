#! /bin/bash

set -euo pipefail
source "$(dirname "$0")/config.sh"
echo "the registration method you chose is $reg_method"
mkdir -p "$sub_dir/temp"
temp_dir="$sub_dir/temp"
if [ ! -d $inputs_dir ]; then
        mkdir -p $inputs_dir
fi

echo "Converting anatomical dicom files to nifti files... "
~/dcmniix/dcm2niix -z y -o "$temp_dir" "$anat_dir"
mv "$temp_dir"/*.nii.gz "$inputs_dir/T1.nii.gz"
mv "$temp_dir"/*.json "$inputs_dir/T1.json"
rm -rf "$temp_dir"/*

echo "Brain extraction using antsBrainExtraction.sh... "
N4BiasFieldCorrection -d 3 -i $t1 -o ${inputs_dir}/T1_n4.nii.gz \
-r 1 -s 4 -v > /dev/null 2>&1
t1="$inputs_dir/T1_n4.nii.gz"

antsBrainExtraction.sh -d 3 -a $t1 -e $MNI\
      -m $MNIMASK -o "${inputs_dir}/T1_" > /dev/null 2>&1


t1_brain="${inputs_dir}/T1_BrainExtractionBrain.nii.gz"
t1_brain="${inputs_dir}/T1_BrainExtractionBrain.nii.gz"
t1_brain_mask="${inputs_dir}/T1_BrainExtractionMask.nii.gz"

echo "🧠🔄 Aligning Anatomical brain to MNI brain 🔄🧩"

if [ "$reg_method" = "ants" ]; then
    echo "Using ANTs for registration..."

    antsRegistration -d 3 \
    -o "${inputs_dir}/T1_to_MNI_" \
    -v -u 1 -z 1 \
    --winsorize-image-intensities [0.005,0.995] \
    -r [$MNI, $t1, 1] \
    -m MI[$MNI, $t1, 1, 32, regular, 0.25] \
    -c [1000x500x250x100,1e-7,5] \
    -t Rigid[0.1] \
    -f 8x4x2x1 -s 4x2x1x0 \
    -x [","] \
    -m MI[$MNIBRAIN, $t1_brain, 1, 32, regular, 0.25] \
    -c [1000x500x250x100,1e-7,5] \
    -t Affine[0.1] \
    -f 8x4x2x1 -s 4x2x1x0 -x [","] \
    -m cc[$MNIBRAIN, $t1_brain, 1, 4] \
    -m MI[$MNI, $t1, 0.1, 32, regular, 0.25] \
    -c [100x70x50,1e-7,5] \
    -t SyN[0.04,3,0] \
    -f 4x2x1 -s 2x1x0 \
    -x [$MNIMASK, $t1_brain_mask] 

    antsApplyTransforms -d 3 -i $t1 -r $MNI -t ${inputs_dir}/T1_to_MNI_1Warp.nii.gz \
        -t ${inputs_dir}/T1_to_MNI_0GenericAffine.mat -o ${inputs_dir}/T1_in_MNI.nii.gz

elif [ "$reg_method" = "fsl" ]; then
    echo "Using FSL for registration..."
    flirt -in $t1 -ref $MNI -omat ${inputs_dir}/t1_to_mni_flirt.mat -out ${inputs_dir}/T1_in_MNI_flirt \
          -searchrx -30 30 -searchry -30 30 -searchrz -30 30
    fnirt --in=$t1 --aff=${inputs_dir}/t1_to_mni_flirt.mat --cout=${inputs_dir}/t1_to_mni_fnirt_coeffs.nii.gz \
          --config=T1_2_MNI152_2mm  --ref=$MNI 
    applywarp --ref=$MNI --in=$t1 --warp=${inputs_dir}/t1_to_mni_fnirt_coeffs.nii.gz \
          --out=${inputs_dir}/T1_in_MNI_fnirt.nii.gz
else
    echo "Invalid registration method specified. Please use 'ants' or 'fsl'."
    exit 1
fi

echo "segmentation"
fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -o "${inputs_dir}/T1_seg" $t1_brain > /dev/null 2>&1

mv ${inputs_dir}/T1_seg_pve_0.nii.gz ${inputs_dir}/T1_CSF.nii.gz
mv ${inputs_dir}/T1_seg_pve_1.nii.gz ${inputs_dir}/T1_GM.nii.gz
mv ${inputs_dir}/T1_seg_pve_2.nii.gz ${inputs_dir}/T1_WM.nii.gz


