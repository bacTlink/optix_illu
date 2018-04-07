import numpy as np
import subprocess
import copy
import os
import math
import concurrent.futures

cuda_devices = [0, 3, 5]
binfile = os.path.join(os.path.split(os.path.realpath(__file__))[0], '../bin/primePPM')
basic_options = ['-n']
dst_dir = '/data3/lzh/10000x224x224_ring_images_diff/'
max_threads_per_device = 2
cuda_device_pointer = 0

if not os.path.exists(dst_dir):
    os.makedirs(dst_dir)

def run_ppm(cuda_device, light_r, light_theta, light_phi):
    light_property = [light_r, light_theta, light_phi]
    light_options = [str(x) for x in light_property]
    light_round_options = [str(round(x, 4)) for x in light_property]
    options = copy.copy(basic_options)
    options.append('--file ' + os.path.join(dst_dir, 'rings--') + '--'.join(light_round_options))
    options.append('--light ' + ' '.join(light_options))
    command = 'CUDA_VISIBLE_DEVICES=' + str(cuda_device) + ' ' + binfile + ' ' + ' '.join(options);
    options.append('-pm 10')
    options.append('-dr2 0.1')
    options.append('-mr')
    print command
    subprocess.call([command], shell=True)
    options.pop()
    options.pop()
    options.pop()
    command = 'CUDA_VISIBLE_DEVICES=' + str(cuda_device) + ' ' + binfile + ' ' + ' '.join(options);
    print command
    subprocess.call([command], shell=True)

executors = [concurrent.futures.ThreadPoolExecutor(max_workers = max_threads_per_device)
        for _ in cuda_devices]
for light_r in np.linspace(800, 1200, 10):
    for light_theta in np.linspace(0.4, 1.4, 25):
        for light_phi in np.linspace(0.0, math.pi * 2, 40, endpoint = False):
            cuda_device_pointer = (cuda_device_pointer + 1) % len(cuda_devices)
            executors[cuda_device_pointer].submit(run_ppm,
                    cuda_devices[cuda_device_pointer],
                    light_r, light_theta, light_phi)
