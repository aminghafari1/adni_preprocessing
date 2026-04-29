import sys
import numpy as np


def main():
    if len(sys.argv) != 4:
        print("Usage: python3 build_confounds.py <init_confounds> <fd_regressors> <output>")
        sys.exit(1)

    init_file = sys.argv[1]
    fd_file = sys.argv[2]
    out_file = sys.argv[3]

    # Load initial confounds (motion + WM + CSF)
    X = np.loadtxt(init_file)
    X = np.atleast_2d(X)

    # Demean all columns
    X = X - X.mean(axis=0, keepdims=True)

    # Load FD regressors (can be empty)
    try:
        fd = np.loadtxt(fd_file)
        fd = np.atleast_2d(fd)

        # If only one column, fix shape
        if fd.ndim == 1:
            fd = fd.reshape(-1, 1)

        # Check matching timepoints
        if fd.shape[0] != X.shape[0]:
            raise ValueError("FD regressors and confounds have different number of timepoints")

        # Concatenate
        X_final = np.hstack((X, fd))

    except Exception:
        print("No FD regressors found or empty file — using only base confounds.")
        X_final = X

    # Save
    np.savetxt(out_file, X_final, fmt="%.6f")
    print(f"Final confound matrix saved: {out_file}", file=sys.stderr)
    print(f"Shape: {X_final.shape}", file=sys.stderr)

    print(X_final.shape[1])

if __name__ == "__main__":
    main()