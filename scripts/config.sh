#!/usr/bin/env bash

# ========================
# SUBJECT / PATH SETTINGS
# ========================
sub_code="002_0413"
base_dir="/home/aghaffari/adni"
sub_dir="$base_dir/$sub_code"
fmri_dir="$sub_dir/func/2019-08-27_09_39_37.0/I1221056"  ## Automate after getting some more subjects
fmap_dir="$sub_dir/fmap/2019-08-27_09_39_37.0"
anat_dir="$sub_dir/anat/2019-08-27_09_39_37.0/I1221051"
adni_preprocessing="$base_dir/preprocessed"
prep_dir="$adni_preprocessing/$sub_code"
inputs_dir="$prep_dir/compressed_inputs"
prep_fmap="$prep_dir/fmap1"
prep_func="$prep_dir/func1"
prep_anat="$prep_dir/anat1"
prep_transforms="$prep_dir/xfm1"


# ========================
# TEMPLATES (FSL)
# ========================
MNI="${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz"
MNIBRAIN="${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz"
MNIMASK="/home/aghaffari/FDG_mask_2mm.nii.gz"

# ========================
# DEFAULT OPTIONS
# ========================

reg_method="fsl"   # or "fsl"