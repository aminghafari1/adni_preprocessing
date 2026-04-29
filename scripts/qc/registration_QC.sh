#!/bin/bash

set -euo pipefail
source "$PROJECT_ROOT/config.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"



for tissue in WM GM; do
    echo "Calculating Dice coefficient for $tissue..."

    sub_seg=${prep_anat}/MNI_bin_${tissue}.nii.gz

    if [ "$tissue" == "WM" ]; then
        ref_seg=$MNIWM
    elif [ "$tissue" == "GM" ]; then
        ref_seg=$MNIGM
    fi

    echo "The subject segmentation for $tissue is $sub_seg and the reference segmentation is $ref_seg."

    output=$(python3 "$SCRIPT_DIR/dice.py" \
        "$tissue" "$sub_seg" "$ref_seg" "$qc_dir")

    dice_value=$(echo "$output" | grep "DICE_RESULT=" | cut -d= -f2)

    if [ "$tissue" == "WM" ]; then
        export wm_dice="$dice_value"
    elif [ "$tissue" == "GM" ]; then
        export gm_dice="$dice_value"
    fi
done

