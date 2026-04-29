import nibabel as nib
import numpy as np
import sys
from nilearn import plotting

def compute_dice(mask1_path, mask2_path, threshold=0.0):
    # Load images
    img1 = nib.load(mask1_path)
    img2 = nib.load(mask2_path)

    data1 = img1.get_fdata()
    data2 = img2.get_fdata()

    # Check same shape
    if data1.shape != data2.shape:
        raise ValueError("ERROR: Masks must have the same shape!")

    # Binarize (important!)
    mask1 = data1 > threshold
    mask2 = data2 > threshold

    # Compute Dice
    intersection = np.logical_and(mask1, mask2).sum()
    volume_sum = mask1.sum() + mask2.sum()

    if volume_sum == 0:
        return 1.0  # both empty → perfect overlap

    dice = 2.0 * intersection / volume_sum
    return dice


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python dice.py tissue <warped_seg.nii.gz> <standard_seg.nii.gz> qcdir")
        sys.exit(1)
    tissue=sys.argv[1]
    mask1_path = sys.argv[2]
    mask2_path = sys.argv[3]
    qc_dir=sys.argv[4]

    dice_value = compute_dice(mask1_path, mask2_path)
    print(f"DICE_RESULT={dice_value:.4f}")


    display = plotting.plot_roi(
    mask1_path,
    bg_img=mask2_path,
    title=f"{tissue} overlap"
    )
    display.add_contours(mask1_path, colors='red', levels=[0.5], linewidths=2)
    address = f"{qc_dir}/{tissue}_overlap.png"
    display.savefig(address)
    display.close() 
    

    