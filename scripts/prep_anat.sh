#! /bin/bash

sub_dir="/home/aghaffari/adni/002_1261"
anat_dir="/home/aghaffari/adni/002_1261/anat/2019-05-01_12_14_22.0/I1270020"
MNI=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz
MNIbrain=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
MNImask=${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz

mkdir -p "$sub_dir/temp"
temp_dir="$sub_dir/temp"
if [ ! -d "$sub_dir/compressed_inputs" ]; then
        mkdir -p "$sub_dir/compressed_inputs"
fi
inputs_dir="$sub_dir/compressed_inputs"

echo "Converting anatomical dicom files to nifti files... "
~/dcmniix/dcm2niix -z y -o "$temp_dir" "$anat_dir"
mv "$temp_dir"/*.nii.gz "$inputs_dir/T1.nii.gz"
mv "$temp_dir"/*.json "$inputs_dir/T1.json"
rm -rf "$temp_dir"/*

echo "Brain extraction using antsBrainExtraction.sh... "
t1="$inputs_dir/T1.nii.gz"

antsBrainExtraction.sh -d 3 -a $t1 -e $MNI\
      -m $MNImask -o "${inputs_dir}/T1_" > /dev/null 2>&1


t1_brain="${inputs_dir}/T1_BrainExtractionBrain.nii.gz"
t1_brain_mask="${inputs_dir}/T1_BrainExtractionMask.nii.gz"

echo "🧠🔄 Aligning Anatomical brain to MNI brain 🔄🧩"

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
-m MI[$MNIbrain, $t1_brain, 1, 32, regular, 0.25] \
-c [1000x500x250x100,1e-7,5] \
-t Affine[0.1] \
-f 8x4x2x1 -s 4x2x1x0 -x [","] \
-m cc[$MNIbrain, $t1_brain, 1, 4] \
-m MI[$MNI, $t1, 0.1, 32, regular, 0.25] \
-c [100x70x50,1e-7,5] \
-t SyN[0.04,3,0] \
-f 4x2x1 -s 2x1x0 \
-x [$MNImask, $t1_brain_mask] 



t1="$inputs_dir/T1.nii.gz"
t1_brain="${inputs_dir}/T1_BrainExtractionBrain.nii.gz"
t1_brain_mask="${inputs_dir}/T1_BrainExtractionMask.nii.gz"

antsApplyTransforms -d 3 -i $t1 -r $MNI -t ${inputs_dir}/T1_to_MNI_1Warp.nii.gz \
    -t ${inputs_dir}/T1_to_MNI_0GenericAffine.mat -o ${inputs_dir}/T1_in_MNI.nii.gz

echo "segmentation"
fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -o "${inputs_dir}/T1_seg" $t1_brain > /dev/null 2>&1

mv ${inputs_dir}/T1_seg_pve_0.nii.gz ${inputs_dir}/T1_CSF.nii.gz
mv ${inputs_dir}/T1_seg_pve_1.nii.gz ${inputs_dir}/T1_GM.nii.gz
mv ${inputs_dir}/T1_seg_pve_2.nii.gz ${inputs_dir}/T1_WM.nii.gz


