#!/usr/bin/env bash

# ========================
# SUBJECT / PATH SETTINGS
# ========================

sub_dir="/home/aghaffari/adni/002_1261"
inputs_dir="$sub_dir/compressed_inputs1"
fmri_dir="/home/aghaffari/adni/002_1261/func/2019-05-01_12_14_22.0/I1270025"  ## Automate after getting some more subjects
phase_dir="/home/aghaffari/adni/002_1261/fmap/2019-05-01_12_14_22.0/I1270031"
mag1_dir="/home/aghaffari/adni/002_1261/fmap/2019-05-01_12_14_22.0/I1270026"
mag2_dir="/home/aghaffari/adni/002_1261/fmap/2019-05-01_12_14_22.0/I1270032"
anat_dir="/home/aghaffari/adni/002_1261/anat/2019-05-01_12_14_22.0/I1270020"
# ========================
# TEMPLATES (FSL)
# ========================

MNI="${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz"
MNIBRAIN="${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz"
MNIMASK="${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz"

# ========================
# DEFAULT OPTIONS
# ========================

reg_method="fsl"   # or "fsl"