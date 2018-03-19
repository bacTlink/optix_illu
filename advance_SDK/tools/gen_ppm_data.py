import numpy as np
import shlex, subprocess
import copy
import os
import math
import sys

cuda_device = 0
binfile = os.path.join(os.path.split(os.path.realpath(__file__))[0], '../bin/primePPM')
basic_options = ['-n', '-cpd']
dst_dir = '/data3/lzh/rings/'

if not os.path.exists(dst_dir):
    os.makedirs(dst_dir)

for light_r in np.linspace(800, 1200, 5):
    for light_theta in np.linspace(0.0, math.pi / 2, 20):
        for light_phi in np.linspace(0.0, math.pi * 2, 20):
            light_property = [light_r, light_theta, light_phi]
            light_options = [str(x) for x in light_property]
            light_round_options = [str(round(x, 2)) for x in light_property]
            options = copy.copy(basic_options)
            options.append('--file ' + os.path.join(dst_dir, 'rings--') + '--'.join(light_round_options))
            options.append('--light ' + ' '.join(light_options))
            command = 'CUDA_VISIBLE_DEVICES=' + str(cuda_device) + ' ' + binfile + ' ' + ' '.join(options);
            print command
            subprocess.call([command], shell=True)
