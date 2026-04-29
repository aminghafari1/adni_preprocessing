import numpy as np
import sys

# Arguments
par_file = sys.argv[1]
out_file = sys.argv[2]

# Load motion parameters
# Columns: rot_x, rot_y, rot_z, trans_x, trans_y, trans_z
motion = np.loadtxt(par_file)

# Initialize FD
fd = np.zeros(motion.shape[0])
radius = 50  # mm

# Compute FD
for i in range(1, motion.shape[0]):
    rx, ry, rz = motion[i, :3] - motion[i-1, :3]
    dx, dy, dz = motion[i, 3:] - motion[i-1, 3:]
    
    fd[i] = abs(dx) + abs(dy) + abs(dz) + radius * (abs(rx) + abs(ry) + abs(rz))
    
# Save
np.savetxt(out_file, fd, fmt="%.4f")