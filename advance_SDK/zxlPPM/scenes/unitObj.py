f = open('clocks/clocks.obj')
out = open('clocks/clocks-unit.obj', 'w')


scale = 0.999782


tranlate = [0,0,0]

lines = f.readlines()

total = 0
for line in lines:
    if line[0] == 'v' and line[1] == ' ':
        tmp = line.strip().split(' ')
        tmp = [float(x) for x in tmp[1:]]
        tmp = [(x - y) * scale for x, y in zip(tmp, tranlate)]
        out.write('v {x} {y} {z}\n'.format(x = tmp[0], y = tmp[1], z = tmp[2]))
    else:
        out.write(line)
