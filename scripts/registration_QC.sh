#!/bin/bash

set -euo pipefail
source "$(dirname "$0")/config.sh"



for tissue in WM GM; do
    echo "Calculating Dice coefficient for $tissue..."
    sub_seg=${prep_anat}/MNI_bin_${tissue}.nii.gz
    if [ $tissue == "WM" ]; then
        ref_seg=$MNIWM
    elif [ $tissue == "GM" ]; then
        ref_seg=$MNIGM
    fi 
    echo "The subject segmentation for $tissue is $sub_seg and the reference segmentation is $ref_seg."
    python3 dice.py $tissue $sub_seg $ref_seg $qc_dir 
done

