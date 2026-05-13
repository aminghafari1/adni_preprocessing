#!/usr/bin/env bash
# Removes intermediate preprocessing files for a batch of subjects.
# By default runs in DRY-RUN mode — nothing is deleted.
# Pass --delete to actually remove files.
#
# Usage:
#   bash cleanup_intermediates.sh [--delete] <group> <sub1> <sub2> ...
#
# Examples:
#   bash cleanup_intermediates.sh CN 002_0413 002_1261 002_1280
#   bash cleanup_intermediates.sh --delete CN 002_0413 002_1261 002_1280

set -euo pipefail

# ── argument parsing ──────────────────────────────────────────────────────────
DRY_RUN=true
if [[ "${1:-}" == "--delete" ]]; then
    DRY_RUN=false
    shift
fi

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 [--delete] <group> <sub1> [sub2 ...]"
    echo "  group: CN or MCI"
    exit 1
fi

GROUP="$1"; shift
SUBS=("$@")

BASE_DIR="/home/aghaffari/adni"
PREP_DIR="$BASE_DIR/preprocessed"

if $DRY_RUN; then
    echo "DRY RUN — no files will be deleted. Pass --delete to actually remove."
else
    echo "DELETING files for ${#SUBS[@]} subject(s) in group $GROUP."
    read -rp "Are you sure? (yes/no): " confirm
    [[ "$confirm" == "yes" ]] || { echo "Aborted."; exit 0; }
fi

echo ""

total_freed=0

# ── per-subject cleanup ───────────────────────────────────────────────────────
for sub in "${SUBS[@]}"; do
    sub_prep="$PREP_DIR/$GROUP/$sub"

    if [[ ! -d "$sub_prep" ]]; then
        echo "[$sub] WARNING: directory not found ($sub_prep), skipping."
        continue
    fi

    func_dir="$sub_prep/func"
    anat_dir="$sub_prep/anat"
    fmap_dir="$sub_prep/fmap"
    xfm_dir="$sub_prep/xfm"
    inp_dir="$sub_prep/compressed_inputs"

    targets=()

    # func: intermediate 4D volumes (the final output is fmri_MNI_preprocessed.nii.gz)
    if [[ -d "$func_dir" ]]; then
        for f in \
            fmri_stc.nii.gz \
            fmri_mc.nii.gz \
            fmri_sc1.nii.gz \
            fmri_sc.nii.gz \
            fmri_sc_MNI.nii.gz \
            fmri_MNI_smoothed.nii.gz \
            fmri_MNI_nuireg.nii.gz \
            fmri_input_MNI.nii.gz; do
            [[ -f "$func_dir/$f" ]] && targets+=("$func_dir/$f")
        done
    fi

    # anat: FAST intermediates and native-space / probability-map segmentations
    if [[ -d "$anat_dir" ]]; then
        for f in \
            T1_n4.nii.gz \
            T1_in_MNI_init.nii.gz \
            T1_CSF.nii.gz \
            T1_GM.nii.gz \
            T1_WM.nii.gz \
            T1_seg_mixeltype.nii.gz \
            T1_seg_pveseg.nii.gz \
            T1_seg_seg.nii.gz \
            MNI_CSF.nii.gz \
            MNI_WM.nii.gz \
            MNI_GM.nii.gz \
            FDG_mask_in_T1.nii.gz; do
            [[ -f "$anat_dir/$f" ]] && targets+=("$anat_dir/$f")
        done
    fi

    # fmap: all fieldmap intermediates (not needed after registration)
    if [[ -d "$fmap_dir" ]]; then
        for f in \
            fieldmap_rads.nii.gz \
            fieldmap_smooth.nii.gz \
            fieldmap_epi.nii.gz \
            mag1_brain.nii.gz \
            mag2_brain.nii.gz \
            mag1_brain_warped.nii.gz \
            mag1_to_epi.nii.gz; do
            [[ -f "$fmap_dir/$f" ]] && targets+=("$fmap_dir/$f")
        done
    fi

    # xfm: epi_reg intermediates and init transforms
    if [[ -d "$xfm_dir" ]]; then
        for f in \
            fmri_to_T1_fast_wmedge.nii.gz \
            fmri_to_T1_fast_wmseg.nii.gz \
            fmri_to_T1_init.mat \
            t1_to_mni_init.mat; do
            [[ -f "$xfm_dir/$f" ]] && targets+=("$xfm_dir/$f")
        done
    fi

    # compressed_inputs: copies of raw data already present in CN/MCI
    if [[ -d "$inp_dir" ]]; then
        targets+=("$inp_dir")
    fi

    # ── report / delete ───────────────────────────────────────────────────────
    if [[ ${#targets[@]} -eq 0 ]]; then
        echo "[$sub] Nothing to clean up."
        continue
    fi

    sub_bytes=0
    echo "[$sub]"
    for t in "${targets[@]}"; do
        size=$(du -sb "$t" 2>/dev/null | awk '{print $1}')
        size_h=$(du -sh "$t" 2>/dev/null | awk '{print $1}')
        rel="${t#$sub_prep/}"
        echo "  ${size_h}  $rel"
        sub_bytes=$(( sub_bytes + size ))
    done

    sub_mb=$(( sub_bytes / 1024 / 1024 ))
    echo "  → would free ~${sub_mb} MB"
    total_freed=$(( total_freed + sub_bytes ))

    if ! $DRY_RUN; then
        for t in "${targets[@]}"; do
            rm -rf "$t"
        done
        echo "  ✓ deleted"
    fi

    echo ""
done

total_gb=$(echo "scale=1; $total_freed / 1024 / 1024 / 1024" | bc)
if $DRY_RUN; then
    echo "Total space that would be freed: ~${total_gb} GB"
else
    echo "Total space freed: ~${total_gb} GB"
fi
