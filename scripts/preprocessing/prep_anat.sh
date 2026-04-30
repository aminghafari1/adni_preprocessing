#! /bin/bash

set -euo pipefail
source "$PROJECT_ROOT/config.sh"
echo "the registration method you chose is $reg_method"
mkdir -p "$prep_anat"

t1_init="${inputs_dir}/T1.nii.gz"


echo "Brain extraction and bias field correction"
N4BiasFieldCorrection -d 3 -i $t1_init -o ${prep_anat}/T1_n4.nii.gz \
-r 1 -s 4 -v > /dev/null 2>&1
t1="$prep_anat/T1_n4.nii.gz"

echo "🧠🔄 Aligning Anatomical brain to MNI brain 🔄🧩"

if [ "$reg_method" = "ants" ]; then
    echo "Using ANTs for brain extraction and registration..."
    echo "Brain extraction"
    antsBrainExtraction.sh -d 3 -a $t1 -e $MNI\
         -m $MNIMASK -o "${prep_anat}/T1_" > /dev/null 2>&1
    mv ${prep_anat}/T1_BrainExtractionBrain.nii.gz ${prep_anat}/T1_brain.nii.gz
    mv ${prep_anat}/T1_BrainExtractionMask.nii.gz ${prep_anat}/T1_brain_mask.nii.gz
    t1_brain="${prep_anat}/T1_brain.nii.gz"
    t1_brain_mask="${prep_anat}/T1_brain_mask.nii.gz"
    echo "Registration"
    antsRegistration -d 3 \
    -o "${prep_transforms}/T1_to_MNI_" \
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

    antsApplyTransforms -d 3 -i $t1 -r $MNI -t ${prep_transforms}/T1_to_MNI_1Warp.nii.gz \
        -t ${prep_transforms}/T1_to_MNI_0GenericAffine.mat -o ${prep_anat}/T1_in_MNI.nii.gz

elif [ "$reg_method" = "fsl" ]; then
    echo "Using FSL for registration..."
    flirt -in $t1 -ref $MNI -omat ${prep_transforms}/t1_to_mni_init.mat -out ${prep_anat}/T1_in_MNI_init \
          -searchrx -30 30 -searchry -30 30 -searchrz -30 30
    fnirt --in=$t1 --aff=${prep_transforms}/t1_to_mni_init.mat --cout=${prep_transforms}/T1_to_MNI.nii.gz \
          --config=T1_2_MNI152_2mm  --ref=$MNI 
    applywarp --ref=$MNI --in=$t1 --warp=${prep_transforms}/T1_to_MNI.nii.gz \
          --out=${prep_anat}/T1_in_MNI.nii.gz
    echo "Now getting MNI to T1 transformation"
    invwarp -w ${prep_transforms}/T1_to_MNI.nii.gz -r $t1 -o ${prep_transforms}/MNI_to_T1.nii.gz
    applywarp --in=$MNIMASK --ref=$t1 --warp=${prep_transforms}/MNI_to_T1.nii.gz \
          --out=${prep_anat}/FDG_mask_in_T1.nii.gz
    fslmaths $t1 -mas ${prep_anat}/FDG_mask_in_T1.nii.gz $prep_anat/T1_brain.nii.gz
    t1_brain="${prep_anat}/T1_brain.nii.gz"
    
else
    echo "Invalid registration method specified. Please use 'ants' or 'fsl'."
    exit 1
fi

echo "segmentation"
fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -o "${prep_anat}/T1_seg" $t1_brain > /dev/null 2>&1

types=("CSF" "GM" "WM")

echo "Renaming and moving segmentations to MNI space"

for i in {0..2}; do
    type=${types[$i]}

    # Rename
    mv ${prep_anat}/T1_seg_pve_${i}.nii.gz ${prep_anat}/T1_${type}.nii.gz

    # Apply warp
    applywarp \
        --in=${prep_anat}/T1_${type}.nii.gz \
        --ref=$MNI \
        --warp=${prep_transforms}/T1_to_MNI.nii.gz \
        --out=${prep_anat}/MNI_${type}.nii.gz

    fslmaths ${prep_anat}/MNI_${type}.nii.gz -thr 0.5 -bin ${prep_anat}/MNI_bin_${type}.nii.gz
done


