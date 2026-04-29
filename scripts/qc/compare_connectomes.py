import os
import sys
import numpy as np
import nibabel as nib
import matplotlib.pyplot as plt

from nilearn.maskers import NiftiLabelsMasker
from nilearn.connectome import ConnectivityMeasure


def upper_triangle_values(mat):
    iu = np.triu_indices_from(mat, k=1)
    return mat[iu]


def compute_connectome(func_path, parc_path):
    masker = NiftiLabelsMasker(
        labels_img=parc_path,
        standardize=True,
        detrend=False,
        verbose=0
    )
    time_series = masker.fit_transform(func_path)

    conn = ConnectivityMeasure(kind="correlation")
    matrix = conn.fit_transform([time_series])[0]
    return matrix


def save_connectomes_side_by_side(raw_conn, proc_conn, out_path):
    vmin = min(raw_conn.min(), proc_conn.min())
    vmax = max(raw_conn.max(), proc_conn.max())

    fig, axes = plt.subplots(
        1, 2,
        figsize=(10, 5),
        constrained_layout=True
    )

    im0 = axes[0].imshow(raw_conn, vmin=vmin, vmax=vmax)
    axes[0].set_title("Raw Connectome")
    axes[0].set_xlabel("Parcel")
    axes[0].set_ylabel("Parcel")

    im1 = axes[1].imshow(proc_conn, vmin=vmin, vmax=vmax)
    axes[1].set_title("Processed Connectome")
    axes[1].set_xlabel("Parcel")
    axes[1].set_ylabel("Parcel")

    cbar = fig.colorbar(
        im1,
        ax=axes,
        location='right',
        fraction=0.02,
        pad=0.04
    )
    cbar.set_label("Correlation")

    plt.savefig(out_path, dpi=200)
    plt.close()



def save_distributions_side_by_side(raw_vals, proc_vals, out_path):
    bins = np.linspace(
        min(raw_vals.min(), proc_vals.min()),
        max(raw_vals.max(), proc_vals.max()),
        80
    )

    fig, axes = plt.subplots(
    1, 2,
    figsize=(10, 5),
    sharey=True,
    constrained_layout=True
    )

    axes[0].hist(raw_vals, bins=bins)
    axes[0].set_title("Raw Distribution")
    axes[0].set_xlabel("Correlation")
    axes[0].set_ylabel("Count")

    axes[1].hist(proc_vals, bins=bins)
    axes[1].set_title("Processed Distribution")
    axes[1].set_xlabel("Correlation")

    
    plt.savefig(out_path, dpi=200)
    plt.close()


def main():
    if len(sys.argv) != 5:
        print("Usage: python3 compare_connectomes.py <raw_MNI> <processed_MNI> <parcellation> <qc_dir>")
        sys.exit(1)

    raw_path = sys.argv[1]
    proc_path = sys.argv[2]
    parc_path = sys.argv[3]
    qc_dir = sys.argv[4]

    os.makedirs(qc_dir, exist_ok=True)

    print("Computing raw connectome...")
    raw_conn = compute_connectome(raw_path, parc_path)

    print("Computing processed connectome...")
    proc_conn = compute_connectome(proc_path, parc_path)

    raw_vals = upper_triangle_values(raw_conn)
    proc_vals = upper_triangle_values(proc_conn)

    save_connectomes_side_by_side(
        raw_conn,
        proc_conn,
        os.path.join(qc_dir, "connectomes_side_by_side.png")
    )

    save_distributions_side_by_side(
        raw_vals,
        proc_vals,
        os.path.join(qc_dir, "distributions_side_by_side.png")
    )

    print("Done.")
    print(f"Saved in: {qc_dir}")


if __name__ == "__main__":
    main()