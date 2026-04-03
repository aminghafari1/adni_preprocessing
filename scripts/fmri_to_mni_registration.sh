#! /bin/bash
cwd="$(pwd)"
set -euo pipefail
source "$(dirname "$0")/config.sh"
t1="$inputs_dir/T1.nii.gz"
t1_brain="$prep_anat/T1_brain.nii.gz"
fmri_sc="$prep_func/fmri_sc.nii.gz"

echo "Calculating mean functional image across time for registration..."
fslmaths $fmri_sc -Tmean $prep_func/fmri_sc_avg.nii.gz
fmri_sc_avg="$prep_func/fmri_mc_avg.nii.gz"

echo "🧠🔄 functional brain to anatomical 🔄🧩"
~/synthstrip-singularity -i $fmri_sc_avg -o $prep_func/fmri_sc_avg_brain.nii.gz -m $prep_func/fmri_sc_avg_brain_mask.nii.gz
fmri_sc_avg_brain="$prep_func/fmri_sc_avg_brain.nii.gz"

if [ "$reg_method" = "fsl" ]; then
    echo "Using fsl for registration..."
    echo "🧠🔄 Now registering functional to anatomical... 🔄"
    epi_reg --epi=$fmri_sc_avg --t1=$t1 --t1brain=$t1_brain --wmseg=$prep_anat/T1_WM.nii.gz --out=$prep_transforms/fmri_to_T1 
    mv $prep_transforms/fmri_to_T1.nii.gz $prep_func/fmri_sc_avg_in_T1.nii.gz  ## only for qc
    aff_fmri_to_t1=$prep_transforms/fmri_to_T1.mat
    t1_to_MNI_warp=$prep_transforms/T1_to_MNI.nii.gz
    ## fnirt already contains t1_to_MNI_init=${inputs_dir}/T1_to_MNI_0GenericAffine.mat, so we don't have its argument here.
    applywarp --in=$fmri_sc_avg --ref=$MNI --warp=$t1_to_MNI_warp --premat=$aff_fmri_to_t1 --out=$prep_func/fmri_avg_in_MNI.nii.gz
    applywarp --in=$fmri_sc_avg_brain --ref=$MNIBRAIN --warp=$t1_to_MNI_warp --premat=$aff_fmri_to_t1 --out=$prep_func/fmri_avg_brain_in_MNI.nii.gz
    #applywarp --in=$fmri_sc --ref=$MNI --warp=$t1_to_MNI_warp --premat=$aff_fmri_to_t1 --out=$inputs_dir/fmri_sc_MNI.nii.gz

elif [ "$reg_method" = "ants" ]; then
    echo "Using ants for registration..."
    echo "🧠🔄 Now registering functional to anatomical... 🔄"

    antsRegistrationSyNQuick.sh \
    -d 3 \
    -f "$t1_brain" \
    -m "$fmri_sc_avg_brain" \
    -t a \
    -o "${prep_transforms}/fmri2T1_"

    aff_fmri_to_t1=${prep_transforms}/fmri2T1_0GenericAffine.mat
    t1_to_MNI_init=${prep_transforms}/T1_to_MNI_0GenericAffine.mat
    t1_to_MNI_warp=${prep_transforms}/T1_to_MNI_1Warp.nii.gz

    antsApplyTransforms -d 3 -i $fmri_avg_brain -r $MNIbrain \
        -t $t1_to_MNI_warp -t $t1_to_MNI_init -t $aff_fmri_to_t1 -o $prep_func/fmri_avg_in_MNI.nii.gz

    input_4d="$fmri_sc"
    output_4d="$prep_func/fmri_sc_MNI.nii.gz"
    ref="$MNI"
    tempdir="$prep_func/tempdir_fmri_MNI"
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
