#!/bin/bash

get_latest_dir () {
    ls -d "$1"/*/ 2>/dev/null | sort | tail -n 1
}

get_single_subdir () {
    dirs=("$1"/*/)

    # remove case where no match (returns literal pattern)
    [ -d "${dirs[0]}" ] || return 1

    if [ ${#dirs[@]} -eq 1 ]; then
        echo "${dirs[0]}"
    else
        echo "Error: expected 1 directory in $1, found ${#dirs[@]}" >&2
        return 1
    fi
}

get_subject_paths () {
    sub_dir=$1

    func_session=$(get_latest_dir "$sub_dir/func")
    anat_session=$(get_latest_dir "$sub_dir/anat")
    fmap_session=$(get_latest_dir "$sub_dir/fmap")

    fmri_dir=$(get_single_subdir "$func_session") || exit 1
    anat_dir=$(get_single_subdir "$anat_session") || exit 1
    fmap_dir=$fmap_session
}

