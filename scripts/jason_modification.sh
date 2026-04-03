#! /bin/bash

set -euo pipefail
source "$(dirname "$0")/config.sh"
echo "Getting the inverse warp from MNI to T1 space for applying to the FDG mask..."
invwarp -w $prep_transforms/T1_to_MNI.nii.gz -r $prep_anat/T1_n4.nii.gz -o $prep_transforms/MNI_to_T1.nii.gz
applywarp --in=/home/aghaffari/FDG_mask_2mm.nii.gz --ref=$prep_anat/T1_n4.nii.gz \
 --warp=$prep_transforms/MNI_to_T1.nii.gz --out=$prep_anat/FDG_mask_in_T1.nii.gz
echo "Brain extraction"
fslmaths $prep_anat/T1_n4.nii.gz -mas $prep_anat/FDG_mask_in_T1.nii.gz $prep_anat/jason_T1_brain.nii.gz
fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -o "${prep_anat}/jason_T1_seg" $prep_anat/jason_T1_brain.nii.gz > /dev/null 2>&1
mv ${prep_anat}/jason_T1_seg_pve_0.nii.gz ${prep_anat}/jason_T1_CSF.nii.gz
mv ${prep_anat}/jason_T1_seg_pve_1.nii.gz ${prep_anat}/jason_T1_GM.nii.gz
mv ${prep_anat}/jason_T1_seg_pve_2.nii.gz ${prep_anat}/jason_T1_WM.nii.gz
echo "epi_reg"
epi_reg --epi=$prep_func/fmri_sc_avg.nii.gz --t1=$prep_anat/T1_n4.nii.gz --t1brain=$prep_anat/jason_T1_brain.nii.gz \
    --wmseg=$prep_anat/jason_T1_WM.nii.gz --out=$prep_transforms/jason_func_to_T1
echo "flirt"
flirt -in $prep_func/fmri_sc_avg.nii.gz -ref $prep_anat/T1_n4.nii.gz -applyxfm -init $prep_transforms/jason_func_to_T1.mat -out $prep_func/jason_fmri_sc_avg_in_T1.nii.gz
applywarp --in=$prep_func/fmri_sc_avg.nii.gz --ref=$MNI --warp=$prep_transforms/T1_to_MNI.nii.gz --premat=$prep_transforms/jason_func_to_T1.mat --out=$prep_func/jason_fmri_avg_in_MNI.nii.gz

