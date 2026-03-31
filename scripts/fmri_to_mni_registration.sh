#! /bin/bash
cwd="$(pwd)"
set -euo pipefail
source "$(dirname "$0")/config.sh"
t1="$inputs_dir/T1.nii.gz"
t1_brain="$inputs_dir/T1_BrainExtractionBrain.nii.gz"
fmri_sc="$inputs_dir/fmri_sc.nii.gz"

<<'COMMENT'
echo "Calculating mean functional image across time for registration..."
fslmaths $fmri_sc -Tmean $inputs_dir/fmri_sc_avg.nii.gz
fmri_sc_avg="$inputs_dir/fmri_sc_avg.nii.gz"

echo "🧠🔄 functional brain to anatomical 🔄🧩"
~/synthstrip-singularity -i $fmri_sc_avg -o $inputs_dir/fmri_sc_avg_brain.nii.gz -m $inputs_dir/fmri_sc_avg_brain_mask.nii.gz
fmri_sc_avg_brain="$inputs_dir/fmri_sc_avg_brain.nii.gz"
COMMENT
fmri_sc_avg="$inputs_dir/fmri_sc_avg.nii.gz"
fmri_sc_avg_brain="$inputs_dir/fmri_sc_avg_brain.nii.gz"
if [ "$reg_method" = "fsl" ]; then
<<'COMMENT'
    echo "Using fsl for registration..."
    echo "🧠🔄 Now registering functional to anatomical... 🔄"
    epi_reg --epi=$fmri_sc_avg --t1=$t1 --t1brain=$t1_brain --wmseg=$inputs_dir/T1_WM.nii.gz --out=$inputs_dir/fmri_to_T1
    flirt -in $fmri_sc_avg -ref $t1 -applyxfm -init $inputs_dir/fmri_to_T1.mat -out $inputs_dir/fmri_sc_avg_in_T1.nii.gz  ## only for qc
COMMENT
    echo "🧠🔄 Now registering anatomical to MNI... 🔄"
    aff_fmri_to_t1=$inputs_dir/fmri_to_T1.mat
    t1_to_MNI_warp=$inputs_dir/t1_to_mni_fnirt_coeffs.nii.gz
    ## fnirt already contains t1_to_MNI_init=${inputs_dir}/T1_to_MNI_0GenericAffine.mat, so we don't have its argument here.
    applywarp --in=$fmri_sc_avg --ref=$MNI --warp=$t1_to_MNI_warp --premat=$aff_fmri_to_t1 --out=$inputs_dir/fmri_avg_in_MNI.nii.gz
    applywarp --in=$fmri_sc_avg_brain --ref=$MNIBRAIN --warp=$t1_to_MNI_warp --premat=$aff_fmri_to_t1 --out=$inputs_dir/fmri_avg_brain_in_MNI.nii.gz
    #applywarp --in=$fmri_sc --ref=$MNI --warp=$t1_to_MNI_warp --premat=$aff_fmri_to_t1 --out=$inputs_dir/fmri_sc_MNI.nii.gz

elif [ "$reg_method" = "ants" ]; then
    echo "Using ants for registration..."
    echo "🧠🔄 Now registering functional to anatomical... 🔄"

    antsRegistrationSyNQuick.sh \
    -d 3 \
    -f "$t1_brain" \
    -m "$fmri_sc_avg_brain" \
    -t a \
    -o "${inputs_dir}/fmri2T1_"

    aff_fmri_to_t1=${inputs_dir}/fmri2T1_0GenericAffine.mat
    t1_to_MNI_init=${inputs_dir}/T1_to_MNI_0GenericAffine.mat
    t1_to_MNI_warp=${inputs_dir}/T1_to_MNI_1Warp.nii.gz

    antsApplyTransforms -d 3 -i $fmri_avg_brain -r $MNIbrain \
        -t $t1_to_MNI_warp -t $t1_to_MNI_init -t $aff_fmri_to_t1 -o $inputs_dir/fmri_avg_in_MNI.nii.gz

    input_4d="$fmri_sc"
    output_4d="$inputs_dir/fmri_sc_MNI.nii.gz"
    ref="$MNI"
    tempdir="$inputs_dir/tempdir_fmri_MNI"
    mkdir -p $tempdir
    cd "$tempdir"
    echo "Splitting 4D fmri data into 3D volumes..."
    fslsplit "$input_4d" vol_ -t

    echo "Applying transforms to each volume..."
    for vol in vol_*.nii.gz; do
        echo "Processing $vol"
        antsApplyTransforms -d 3 -i "$vol" -r "$ref" \
        -t "$t1_to_MNI_warp" -t "$t1_to_MNI_init" -t "$aff_fmri_to_t1" \
        -o "${vol%.nii.gz}_MNI.nii.gz"
    done

    echo "Merging transformed volumes back into 4D fmri data..."
    fslmerge -t "$output_4d" vol_*_MNI.nii.gz
    cd $cwd
    echo "cleaning"
    rm -rf "$tempdir"

else 
    echo "Invalid registration method specified. Please choose 'ants' or 'fsl'."
    exit 1
fi
