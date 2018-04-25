import sys
import numpy as np
import subprocess
import copy
import os
import math
import concurrent.futures
import yaml

cuda_devices = [0]
model_name = 'box'
binfilename = '../bin/zxlPPM'
binfile = os.path.join(os.path.split(os.path.realpath(__file__))[0], binfilename)
basic_options = ['-n']
dst_dir = '/home/bactlink/disk/10000x224x224_' + model_name + '_diff/'
max_threads_per_device = 2

def get_yaml(filename):
    with open(filename) as f:
        content = yaml.load(f)
    return content

if not os.path.exists(dst_dir):
    os.makedirs(dst_dir)

def run_prime_ppm_process(cuda_device, light_r, light_theta, light_phi):
    light_property = [light_r, light_theta, light_phi]
    light_options = [str(x) for x in light_property]
    light_round_options = [str(round(x, 4)) for x in light_property]
    options = copy.copy(basic_options)
    options.append('--file ' + os.path.join(dst_dir, model_name + '--') + '--'.join(light_round_options))
    options.append('--light ' + ' '.join(light_options))
    options.append('-pm 10')
    options.append('-dr2 0.1')
    options.append('-mr')
    command = 'CUDA_VISIBLE_DEVICES=' + str(cuda_device) + ' ' + binfile + ' ' + ' '.join(options);
    print command
    subprocess.call([command], shell=True)
    options.pop()
    options.pop()
    options.pop()
    command = 'CUDA_VISIBLE_DEVICES=' + str(cuda_device) + ' ' + binfile + ' ' + ' '.join(options);
    print command
    subprocess.call([command], shell=True)

def run_prime_ppm():
    cuda_device_pointer = 0
    executors = [concurrent.futures.ThreadPoolExecutor(max_workers = max_threads_per_device)
            for _ in cuda_devices]
    for light_r in np.linspace(800, 1200, 10):
        for light_theta in np.linspace(0.4, 1.4, 25):
            for light_phi in np.linspace(0.0, math.pi * 2, 40, endpoint = False):
                cuda_device_pointer = (cuda_device_pointer + 1) % len(cuda_devices)
                executors[cuda_device_pointer].submit(run_prime_ppm_process,
                        cuda_devices[cuda_device_pointer],
                        light_r, light_theta, light_phi)

def run_zxl_ppm_process(cuda_device, camera_num, light_num, radius_num = 0):
    options = copy.copy(basic_options)
    options.append('--file ' + os.path.join(dst_dir, model_name + '-') + '-c' + str(camera_num) + '-l' + str(light_num) + '-r' + str(radius_num))
    options.append('--model ' + model_name + ' null')
    options.append('--camera ' + str(camera_num))
    options.append('--light ' + str(light_num))
    options.append('--radius ' + str(radius_num))
    options.append('-pm 10')
    options.append('-mr')
    command = 'CUDA_VISIBLE_DEVICES=' + str(cuda_device) + ' ' + binfile + ' ' + ' '.join(options);
    print command
    subprocess.call([command], shell=True)
    options.pop()
    options.pop()
    command = 'CUDA_VISIBLE_DEVICES=' + str(cuda_device) + ' ' + binfile + ' ' + ' '.join(options);
    print command
    subprocess.call([command], shell=True)

def run_zxl_ppm():
    cuda_device_pointer = 0
    executors = [concurrent.futures.ThreadPoolExecutor(max_workers = max_threads_per_device)
            for _ in cuda_devices]
    yaml_file = '../../optix/advance_SDK/zxlPPM/scenes/' + model_name + '/' + model_name + '.yaml'
    yaml_file = os.path.join(os.path.split(os.path.realpath(__file__))[0], yaml_file)
    model_yaml = get_yaml(yaml_file)
    camera_count = len(model_yaml['cameras'])
    light_count = len(model_yaml['lights'])
    print camera_count, 'x', light_count
    for c in xrange(camera_count):
        for l in xrange(light_count):
            cuda_device_pointer = (cuda_device_pointer + 1) % len(cuda_devices)
            executors[cuda_device_pointer].submit(run_zxl_ppm_process,
                    cuda_devices[cuda_device_pointer],
                    c, l)

run_zxl_ppm()
