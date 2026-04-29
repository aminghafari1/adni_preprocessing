import numpy as np
import nibabel as nib
import matplotlib.pyplot as plt
import sys

def compute_carpet_plot(fmri_file):
    # Load the fMRI data
    img = nib.load(fmri_file)
    data = img.get_fdata()
    
    # Reshape the data to 2D (time x voxels)
    n_voxels=np.prod(data.shape[:3])
    time_points=data.shape[3]
    reshaped_data = data.reshape(n_voxels,time_points)
    std=np.std(reshaped_data, axis=1)
    reshaped_data=reshaped_data[std>1e-6]
    reshaped_data=(reshaped_data - np.mean(reshaped_data, axis=1, keepdims=True)) / np.std(reshaped_data, axis=1, keepdims=True)
    
    

    return reshaped_data

if __name__ == "__main__":
    raw=sys.argv[1]
    processed=sys.argv[2]
    motion,dvars=sys.argv[3],sys.argv[4]
    qc_dir=sys.argv[5]
    fd_threshold,dvars_z=float(sys.argv[6]),float(sys.argv[7])
    raw_mean=compute_carpet_plot(raw)
    processed_mean=compute_carpet_plot(processed)
    motion=np.loadtxt(motion)
    dvars=np.loadtxt(dvars)
    print(f"Maximum_FD={motion.max():.4f}")
    high_fd_percent = (motion > fd_threshold).mean() * 100
    print(f"HIGH_FD_PERCENT={high_fd_percent:.2f}")
    fig, axes = plt.subplots(
    4, 1,
    figsize=(10, 8),
    sharex=True,
    gridspec_kw={'height_ratios': [4,4, 1, 1]}
    )

    axes[0].imshow(
        raw_mean,
        aspect='auto',
        cmap='gray',
        interpolation='nearest'
    )
    axes[0].set_ylabel("Voxels")
    axes[0].set_title("Raw Carpet Plot")

    axes[1].imshow(
        processed_mean,
        aspect='auto',
        cmap='gray',
        interpolation='nearest'
    )
    axes[1].set_ylabel("Voxels")
    axes[1].set_title("Preprocessed Carpet Plot")

    # --- FD ---
    axes[2].plot(motion)
    axes[2].set_ylabel("FD")

    # --- DVARS ---
    axes[3].plot(dvars)
    axes[3].set_ylabel("DVARS")
    axes[3].set_xlabel("Time (TRs)")

    # --- FD threshold ---
    fd_threshold = 0.5
    axes[2].axhline(fd_threshold, color='red', linestyle='--', linewidth=1)

    fd_spikes = np.where(motion > fd_threshold)[0]
    for s in fd_spikes:
        axes[2].axvline(s, color='red', linestyle='--', linewidth=1)

    # --- DVARS threshold (3 std) ---
    dvars_mean = np.mean(dvars)
    dvars_std = np.std(dvars)

    if dvars_std != 0:
        dvars_z = (dvars - dvars_mean) / dvars_std
        dvars_spikes = np.where(np.abs(dvars_z) > 3)[0]

        # optional: horizontal line (threshold in original units)
        upper_thr = dvars_mean + 3 * dvars_std
        lower_thr = dvars_mean - 3 * dvars_std
        axes[3].axhline(upper_thr, color='blue', linestyle='--', linewidth=1)
        axes[3].axhline(lower_thr, color='blue', linestyle='--', linewidth=1)

        for s in dvars_spikes:
            axes[3].axvline(s, color='blue', linestyle='--', linewidth=1)

    plt.savefig(f"{qc_dir}/carpet_plot.png", dpi=200)
    plt.close()
    
