#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/config.sh" 

mkdir -p $inputs_dir

echo "$prep_dir"
n_dirs=$(find "$fmap_dir" -mindepth 1 -maxdepth 1 -type d | wc -l)
temp_dir="$sub_dir/temp"
rm -rf "$temp_dir"
mkdir -p "$sub_dir/temp"
if [ "$n_dirs" -eq 3 ]; then
    echo "There are 3 folders, one is for phase, one is for mag1, and one is for mag2."
    for dir in "$fmap_dir"/*/; do
        [ -d "$dir" ] || continue   # safety check
        echo "Processing: $dir"
        if [ ! -d $inputs_dir ]; then
            mkdir -p $inputs_dir
        fi
        echo "Converting dicom files to nifti files... "
        ~/dcmniix/dcm2niix -z y -o "$temp_dir" "$dir"
        for f in "$temp_dir"/*.nii.gz; do
            fname=$(basename "$f")

            if [[ "$fname" == *e2_ph* ]]; then
                echo "Found phase difference: $fname"
                mv "$f" "$inputs_dir/phase_difference.nii.gz"
                mv "$temp_dir"/*.json "$inputs_dir/phase_difference.json"

            elif [[ "$fname" == *e2* && "$fname" != *e2_ph* ]]; then
                echo "Found magnitude2: $fname"
                mv "$f" "$inputs_dir/mag2.nii.gz"
                mv "$temp_dir"/*.json "$inputs_dir/mag2.json"

            else
                echo "Found magnitude1: $fname"
                mv "$f" "$inputs_dir/mag1.nii.gz"
                mv "$temp_dir"/*.json "$inputs_dir/mag1.json"
            fi
        done
        rm -rf "$temp_dir"/*
        
    done

else
    echo "Not 3 folders, please go to pre_config.sh and enter the paths manually."
    # Expect these to be defined in pre_config.sh

    << 'comment'
    mag1_dir=/path/to/mag1
    mag2_dir=/path/to/mag2
    phase_dir=/path/to/phase

    mkdir -p "$sub_dir/temp"
    temp_dir="$sub_dir/temp"
    mkdir -p "$inputs_dir"

    echo "Converting magnitude1..."
    ~/dcmniix/dcm2niix -z y -o "$temp_dir" "$mag1_dir"
    for f in "$temp_dir"/*.nii.gz; do
        mv "$f" "$inputs_dir/mag1.nii.gz"
    done
    for f in "$temp_dir"/*.json; do
        mv "$f" "$inputs_dir/mag1.json"
    done
    rm -rf "$temp_dir"/*

    echo "Converting magnitude2..."
    ~/dcmniix/dcm2niix -z y -o "$temp_dir" "$mag2_dir"
    for f in "$temp_dir"/*.nii.gz; do
        mv "$f" "$inputs_dir/mag2.nii.gz"
    done
    for f in "$temp_dir"/*.json; do
        mv "$f" "$inputs_dir/mag2.json"
    done
    rm -rf "$temp_dir"/*

    echo "Converting phase difference..."
    ~/dcmniix/dcm2niix -z y -o "$temp_dir" "$phase_dir"
    for f in "$temp_dir"/*.nii.gz; do
        mv "$f" "$inputs_dir/phase_difference.nii.gz"
    done
    for f in "$temp_dir"/*.json; do
        mv "$f" "$inputs_dir/phase_difference.json"
    done
    rm -rf "$temp_dir"/*
comment
fi

echo "Converting fMRI dicom files to nifti files... "
~/dcmniix/dcm2niix -z y -o "$temp_dir" "$fmri_dir"
mv "$temp_dir"/*.nii.gz "$inputs_dir/fmri_input.nii.gz"
mv "$temp_dir"/*.json "$inputs_dir/fmri_input.json"
rm -rf "$temp_dir"/*

echo "Converting anatomical dicom files to nifti files... "
~/dcmniix/dcm2niix -z y -o "$temp_dir" "$anat_dir"
mv "$temp_dir"/*.nii.gz "$inputs_dir/T1.nii.gz"
mv "$temp_dir"/*.json "$inputs_dir/T1.json"
rm -rf "$temp_dir"/*
## remove temp dir
rm -rf "$temp_dir"


