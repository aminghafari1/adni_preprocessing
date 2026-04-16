#!/usr/bin/env bash
echo "Entered config.sh"
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CONFIG_DIR/utils_path.sh"

# ========================
# SUBJECT / PATH SETTINGS
# ========================
sub_code="002_0413"
base_dir="/home/aghaffari/adni"
sub_dir="$base_dir/$sub_code"

get_subject_paths "$sub_dir"

adni_preprocessing="$base_dir/preprocessed"
prep_dir="$adni_preprocessing/$sub_code"
inputs_dir="$prep_dir/compressed_inputs"
prep_fmap="$prep_dir/fmap"
prep_func="$prep_dir/func"
confounds_dir="$prep_func/confounds"
prep_anat="$prep_dir/anat"
prep_transforms="$prep_dir/xfm"


# ========================
# TEMPLATES (FSL)
# ========================
MNI="${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz"
MNIBRAIN="${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz"
MNIMASK="/home/aghaffari/FDG_mask_2mm.nii.gz"

# ========================
# DEFAULT OPTIONS
# ========================
SMOOTH_FWHM=5
fd_threshold=0.3
dvars_z=3.0
reg_method="fsl"   # or "fsl"
HP_FREQ=0.01
LP_FREQ=0.1
