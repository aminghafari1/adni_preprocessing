import sys
import argparse
import numpy as np


def expand_motion(motion, model):
    """Expand 6 motion params to 12 or 24 (Friston) model."""
    deriv = np.vstack([np.zeros((1, 6)), np.diff(motion, axis=0)])
    if model == 6:
        return motion
    if model == 12:
        return np.hstack([motion, deriv])
    # 24: original + deriv + squared + squared deriv
    return np.hstack([motion, deriv, motion**2, deriv**2])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("init_confounds")
    parser.add_argument("output")
    parser.add_argument("--motion-model", type=int, choices=[6, 12, 24], default=6)
    args = parser.parse_args()

    X = np.loadtxt(args.init_confounds)
    X = np.atleast_2d(X)

    # First 6 columns are motion params; remainder are tissue signals
    motion = X[:, :6]
    tissue = X[:, 6:]

    motion_expanded = expand_motion(motion, args.motion_model)

    X_final = np.hstack([motion_expanded, tissue])
    X_final = X_final - X_final.mean(axis=0, keepdims=True)

    np.savetxt(args.output, X_final, fmt="%.6f")
    print(f"Final confound matrix saved: {args.output}", file=sys.stderr)
    print(f"Shape: {X_final.shape}", file=sys.stderr)

    print(X_final.shape[1])


if __name__ == "__main__":
    main()
