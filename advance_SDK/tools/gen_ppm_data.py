import numpy as np
import shlex, subprocess
import copy
import os
import math
import sys
from threading import Thread
import Queue

cuda_devices = [0, 1, 2, 5]
binfile = os.path.join(os.path.split(os.path.realpath(__file__))[0], '../bin/primePPM')
basic_options = ['-n', '-cpd']
dst_dir = '/data3/lzh/rings/'
max_threads_per_device = 15
cuda_device_counter = max_threads_per_device
cuda_device_pointer = 0

if not os.path.exists(dst_dir):
    os.makedirs(dst_dir)

def run_ppm(cuda_device, light_r, light_theta, light_phi):
    light_property = [light_r, light_theta, light_phi]
    light_options = [str(x) for x in light_property]
    light_round_options = [str(round(x, 2)) for x in light_property]
    options = copy.copy(basic_options)
    options.append('--file ' + os.path.join(dst_dir, 'rings--') + '--'.join(light_round_options))
    options.append('--light ' + ' '.join(light_options))
    command = 'CUDA_VISIBLE_DEVICES=' + str(cuda_device) + ' ' + binfile + ' ' + ' '.join(options);
    print command
    subprocess.call([command], shell=True)

thread_queue = Queue.Queue(max_threads_per_device * len(cuda_devices))
for light_r in np.linspace(800, 1200, 5):
    for light_theta in np.linspace(0.0, math.pi / 2, 20):
        for light_phi in np.linspace(0.0, math.pi * 2, 20):
            if cuda_device_counter == 0:
                cuda_device_counter = max_threads_per_device
                cuda_device_pointer = (cuda_device_pointer + 1) % len(cuda_devices)
            cuda_device_counter = cuda_device_counter - 1
            new_thread = Thread(target = run_ppm,
                    args = (cuda_devices[cuda_device_pointer], light_r, light_theta, light_phi))
            if not thread_queue.full():
                new_thread.start()
                thread_queue.put(new_thread)
            else:
                old_thread = thread_queue.get()
                old_thread.join()
                new_thread.start()
                thread_queue.put(new_thread)

while not thread_queue.empty():
    old_thread = thread_queue.get()
    old_thread.join()
