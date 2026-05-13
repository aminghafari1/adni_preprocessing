#!/bin/bash

set -euo pipefail
source "$PROJECT_ROOT/config.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Running synthstrip for brain extraction on the magnitude images... "
~/synthstrip-singularity -i "$inputs_dir/mag1.nii.gz" -o "$prep_fmap/mag1_brain.nii.gz" 
~/synthstrip-singularity -i "$inputs_dir/mag2.nii.gz" -o "$prep_fmap/mag2_brain.nii.gz" 

echo "Getting mean of the fMRI time series for registration... "
fslmaths "$prep_func/fmri_mc.nii.gz" -Tmean "$prep_func/fmri_mc_avg.nii.gz"
~/synthstrip-singularity -i "$prep_func/fmri_mc_avg.nii.gz" -o "$prep_func/fmri_mc_avg_brain.nii.gz" -m "$prep_func/fmri_mc_avg_brain_mask.nii.gz"

echo "Get delta TE in milliseconds from the json file... "
DELTA_TE=$(python3 -c "
import json
with open('$inputs_dir/phase_difference.json') as f:
    meta = json.load(f)

te1 = float(meta['EchoTime1'])
te2 = float(meta['EchoTime2'])

print(abs(te2 - te1) * 1000)
")

echo "Preparing the fieldmap using FSL's fsl_prepare_fieldmap... "
fsl_prepare_fieldmap SIEMENS "$inputs_dir/phase_difference.nii.gz" "$prep_fmap/mag1_brain.nii.gz" "$prep_fmap/fieldmap_rads.nii.gz" $DELTA_TE
## This 2.46 is the difference between the two TEs and should be automated later by reading the json files.

echo "We need to take the field map to the same space as EPI, first, smooth using fugue."
fugue --loadfmap="$prep_fmap/fieldmap_rads.nii.gz" -s $fieldmap_smoothing_fwhm --savefmap="$prep_fmap/fieldmap_smooth.nii.gz"

dwell=$(python3 -c "import json; print(json.load(open('$inputs_dir/fmri_input.json'))['EffectiveEchoSpacing'])")

PHASE_DIR=$(python3 "$SCRIPT_DIR/get_pe.py" "$inputs_dir/fmri_input.json")
echo "The phase encoding direction is: $PHASE_DIR"
# PHASE_DIR="y"    ## in case of a manual overwrite requirement
case "$PHASE_DIR" in
    x)  UNWARP_DIR="x-" ;;
    x-) UNWARP_DIR="x"  ;;
    y)  UNWARP_DIR="y-" ;;
    y-) UNWARP_DIR="y"  ;;
    z)  UNWARP_DIR="z-" ;;
    z-) UNWARP_DIR="z"  ;;
    *)  echo "ERROR: Unknown phase encoding direction: $PHASE_DIR"; exit 1 ;;
esac

echo "Warping the magnitude image using the fieldmap."
fugue -i "$prep_fmap/mag1_brain.nii.gz" --dwell="$dwell" --unwarpdir="$PHASE_DIR" --loadfmap="$prep_fmap/fieldmap_smooth.nii.gz" -u "$prep_fmap/mag1_brain_warped.nii.gz"

echo "Registering the unwarped magnitude image to EPI image"
flirt -in "$prep_fmap/mag1_brain_warped.nii.gz" -ref "$prep_func/fmri_mc_avg_brain.nii.gz" -out "$prep_fmap/mag1_to_epi.nii.gz" -omat "$prep_transforms/mag1_to_epi.mat" -dof 6 -cost normmi

echo "Taking the field map to the EPI space."
flirt -in "$prep_fmap/fieldmap_smooth.nii.gz" -ref "$prep_func/fmri_mc_avg_brain.nii.gz" -applyxfm -init "$prep_transforms/mag1_to_epi.mat" -out "$prep_fmap/fieldmap_epi.nii.gz"

echo "Trying both PE directions to find the better SDC correction..."
case "$UNWARP_DIR" in
    x)  UNWARP_DIR_OPP="x-" ;;  x-) UNWARP_DIR_OPP="x" ;;
    y)  UNWARP_DIR_OPP="y-" ;;  y-) UNWARP_DIR_OPP="y" ;;
    z)  UNWARP_DIR_OPP="z-" ;;  z-) UNWARP_DIR_OPP="z" ;;
esac

fugue -i "$prep_func/fmri_mc_avg_brain.nii.gz" --dwell="$dwell" \
    --unwarpdir="$UNWARP_DIR" --loadfmap="$prep_fmap/fieldmap_epi.nii.gz" \
    -u "$prep_func/sdc_test_fwd.nii.gz"

fugue -i "$prep_func/fmri_mc_avg_brain.nii.gz" --dwell="$dwell" \
    --unwarpdir="$UNWARP_DIR_OPP" --loadfmap="$prep_fmap/fieldmap_epi.nii.gz" \
    -u "$prep_func/sdc_test_rev.nii.gz"

BEST_UNWARP_DIR=$(python3 "$SCRIPT_DIR/compare_sdc.py" \
    "$prep_func/sdc_test_fwd.nii.gz" "$UNWARP_DIR" \
    "$prep_func/sdc_test_rev.nii.gz" "$UNWARP_DIR_OPP" \
    "$inputs_dir/T1.nii.gz")

echo "Selected unwarp direction: $BEST_UNWARP_DIR (JSON suggested: $UNWARP_DIR)"
echo "json_suggested: $UNWARP_DIR" > "$qc_dir/pe_direction.txt"
echo "used: $BEST_UNWARP_DIR" >> "$qc_dir/pe_direction.txt"
mv "$prep_func/sdc_test_fwd.nii.gz" "$qc_dir/sdc_candidate_${UNWARP_DIR//\-/minus}.nii.gz"
mv "$prep_func/sdc_test_rev.nii.gz" "$qc_dir/sdc_candidate_${UNWARP_DIR_OPP//\-/minus}.nii.gz"

echo "Applying the fieldmap to unwarp the fMRI average brain image."
fugue -i "$prep_func/fmri_mc_avg_brain.nii.gz" --dwell="$dwell" \
    --unwarpdir="$BEST_UNWARP_DIR" --loadfmap="$prep_fmap/fieldmap_epi.nii.gz" \
    -u "$prep_func/fmri_sc_mean_test.nii.gz"

echo "Now applying the same unwarping to the entire fMRI time series... "
fugue -i "$prep_func/fmri_mc.nii.gz" --dwell="$dwell" \
    --unwarpdir="$BEST_UNWARP_DIR" --loadfmap="$prep_fmap/fieldmap_epi.nii.gz" \
    -u "$prep_func/fmri_sc.nii.gz"