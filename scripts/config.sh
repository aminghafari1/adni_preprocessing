#!/usr/bin/env bash
echo "Entered config.sh"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📂 Project root: $PROJECT_ROOT"
export PROJECT_ROOT
source "$PROJECT_ROOT/utils_path.sh"

# ========================
# SUBJECT / PATH SETTINGS
# ========================
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
qc_dir="$prep_dir/qc"


# ========================
# TEMPLATES (FSL)
# ========================
MNI="${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz"
MNIBRAIN="${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz"
MNIMASK="/home/aghaffari/FDG_mask_2mm.nii.gz"
MNIGM="${base_dir}/MNI_segmentation/MNI_GM.nii.gz"
MNIWM="${base_dir}/MNI_segmentation/MNI_WM.nii.gz"
MNIPARCEL="${base_dir}/MNI_segmentation/shen_2mm_268_parcellation.nii.gz"
# ========================
# DEFAULT OPTIONS
# ========================
SMOOTH_FWHM=5
fd_threshold=0.5
dvars_z=3.0
reg_method="fsl"   # or "fsl"
HP_FREQ=0.01
LP_FREQ=0.25
