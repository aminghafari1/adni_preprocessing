set -euo pipefail
source "$PROJECT_ROOT/config.sh"

mkdir -p "$qc_dir"

echo "QC part 1, calculate tSNR of the smoothed scan and compare it across subjects and regions"
source "$PROJECT_ROOT/qc/tsnr_QC.sh" \
    "${prep_func}/fmri_MNI_smoothed.nii.gz" \
    "${qc_dir}/tsnr_MNI.nii.gz" \
    "$MNIMASK"

echo "QC part 2, registration from T1 to MNI space using dice coefficient for gray matter and white matter masks."
source "$PROJECT_ROOT/qc/registration_QC.sh"

echo "QC part 3, Let's take a look at the connectomes and their distributions."
source "$PROJECT_ROOT/qc/connectome_QC.sh"

echo "QC part 4, let's get carpet plots of raw and preprocessed data in MNI space, and check their alignment with motion and dvars outliers."
source "$PROJECT_ROOT/qc/carpet_QC.sh"

qc_csv="$qc_dir/qc_summary.csv"

mkdir -p "$(dirname "$qc_csv")"

if [ ! -f "$qc_csv" ]; then
    echo "Subject,tsnr_mean,tsnr_median,dice_gm,dice_wm,max_fd,high_fd_percent" > "$qc_csv"
fi

echo "$sub_code,$mean_tsnr,$median_tsnr,$gm_dice,$wm_dice,$max_fd,$high_fd_percent" >> "$qc_csv"