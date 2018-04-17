import yaml

f = open('box/box1.yaml')
x = yaml.load(f)


scale = 0.166667
cx = 0.000000 
cy = 2.250000
cz = 0.000000

def trans(p):
    p = [x / scale for x in p]
    return [p[0] + cx, p[1] + cy, p[2] + cz]

def tranx(p):
    return p / scale + cx
    
def trany(p):
    return p / scale + cy
    
def tranz(p):
    return p / scale + cz

x['camera_data']['eye'] = trans(x['camera_data']['eye'])
x['camera_data']['lookat'] = trans(x['camera_data']['lookat'])

light = x['light_data']
light['position'] = trans(light['position'])
if light['target']:
    light['target'] = trans(light['target'])
light['v1'] = tranx(light['v1'])
light['v2'] = tranz(light['v2'])
light['power'] = [tmp / scale for tmp in light['power']]
x['default_radius'] /= scale

# yaml.dump(x, open('box/box9.yaml',  "w"))
print(trans([0.428605,-0.616445,0.427188]))


