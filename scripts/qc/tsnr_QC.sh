#!/bin/bash
set -euo pipefail

source "$PROJECT_ROOT/config.sh"

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <fmri_4D.nii.gz> <output_tsnr.nii.gz> <brain_mask.nii.gz>"
    exit 1
fi

fmri_file="$1"
tsnr_out="$2"
brain_mask="$3"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out_dir="$(dirname "$tsnr_out")"
mean_img="$out_dir/temp_mean.nii.gz"
std_img="$out_dir/temp_std.nii.gz"
std_safe="$out_dir/temp_std_safe.nii.gz"

echo "Calculating temporal mean..."
fslmaths "$fmri_file" -Tmean "$mean_img"

echo "Calculating temporal std..."
fslmaths "$fmri_file" -Tstd "$std_img"

echo "Adding small value to std to avoid division by zero..."
fslmaths "$std_img" -add 1e-6 "$std_safe"

echo "Calculating masked tSNR = mean / std ..."
fslmaths "$mean_img" -div "$std_safe" -mas "$brain_mask" "$tsnr_out"

echo "Calculating mean and median tSNR inside mask..."
mean_tsnr=$(fslstats "$tsnr_out" -k "$brain_mask" -M)
median_tsnr=$(fslstats "$tsnr_out" -k "$brain_mask" -P 50)

export mean_tsnr
export median_tsnr

echo "Done."
echo "tSNR map saved to: $tsnr_out"

echo "Cleaning temporary files..."
rm -f "$mean_img" "$std_img" "$std_safe"

echo "Going for region-based tSNR calculation..."
python3 "$SCRIPT_DIR/regions_tsnr.py" $fmri_file $out_dir $MNIPARCEL