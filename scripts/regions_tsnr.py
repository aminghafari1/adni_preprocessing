import os
import sys
import numpy as np
import nibabel as nib
import matplotlib.pyplot as plt

from nilearn.maskers import NiftiLabelsMasker
from nilearn.connectome import ConnectivityMeasure

def compute_connectome(func_path, parc_path):
    masker = NiftiLabelsMasker(
        labels_img=parc_path,
        standardize=False,
        detrend=False,
        verbose=0
    )
    time_series = masker.fit_transform(func_path)

    return time_series

## calculate mean of time series for each region
print("Calculating mean time series for each region...")
time_series=compute_connectome(sys.argv[1], sys.argv[3])
ts_mean = time_series[0, :]
address=os.path.join(sys.argv[2], "tsnr_per_region.txt")
np.savetxt(address, ts_mean, fmt='%.3f')