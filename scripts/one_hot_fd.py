import sys
import numpy as np


def main():
    if len(sys.argv) != 6:
        print("Usage: python3 one_hot_fd.py <fd_file> <dvars_file> <output_file> <fd_threshold> <dvars_z_threshold>")
        sys.exit(1)

    fd_file = sys.argv[1]
    dvars_file = sys.argv[2]
    output_file = sys.argv[3]
    fd_threshold = float(sys.argv[4])
    dvars_z_threshold = float(sys.argv[5])

    fd = np.loadtxt(fd_file)
    dvars = np.loadtxt(dvars_file)

    fd = np.atleast_1d(fd)
    dvars = np.atleast_1d(dvars)

    if len(fd) != len(dvars):
        print(f"Error: FD length ({len(fd)}) and DVARS length ({len(dvars)}) do not match.")
        sys.exit(1)

    # FD outliers
    bad_fd_idx = np.where(fd > fd_threshold)[0]

    # DVARS outliers: z-score relative to mean and std
    dvars_mean = np.mean(dvars)
    dvars_std = np.std(dvars)

    if dvars_std == 0:
        bad_dvars_idx = np.array([], dtype=int)
    else:
        dvars_z = (dvars - dvars_mean) / dvars_std
        bad_dvars_idx = np.where(np.abs(dvars_z) > dvars_z_threshold)[0]

    # Union of bad volumes
    bad_idx = np.union1d(bad_fd_idx, bad_dvars_idx)

    n_timepoints = len(fd)
    n_bad = len(bad_idx)

    if n_bad == 0:
        open(output_file, "w").close()
        return

    censor = np.zeros((n_timepoints, n_bad), dtype=int)
    for col, idx in enumerate(bad_idx):
        censor[idx, col] = 1

    np.savetxt(output_file, censor, fmt="%d")


if __name__ == "__main__":
    main()