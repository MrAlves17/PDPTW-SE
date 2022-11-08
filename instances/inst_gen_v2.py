import os
import pandas as pd
import random
import math

div_line = 0

def gen_z_values(tasks):
	z = []
	for _,row in tasks.iterrows():
		if int(row['x']) <= div_line:
			z.append(0)
		else:
			z.append(1)

	return z

def gen_tasks(inst_lines):
	col_names = ['task_no', 'x', 'y', 'dem', 'earl', 'lat', 'servt', 'pid', 'did']
	tasks = pd.DataFrame(inst_lines[1:], columns=col_names)
	x_values = [int(tasks['x'][i]) for i in range(len(tasks['x']))]
	global div_line
	div_line = math.ceil((max(x_values)+min(x_values))/2)
	tasks.insert(3, 'z', gen_z_values(tasks))
	# print(tasks)
	tasks.to_csv('tasks.csv', header=False, index=False)
	return tasks

def choose_capacity(capacity):
	possible_caps = [int(math.floor(0.8*capacity)), capacity, int(math.floor(1.2*capacity))]
	return possible_caps[random.randint(0, len(possible_caps)-1)]
	# return capacity

def gen_vehicles(n_vehicles, capacity):
	vehicles = []
	for i in range(n_vehicles):
		vehicles.append([i, choose_capacity(capacity)])

	vehicles = pd.DataFrame(vehicles, columns=['v_no', 'cap'])
	# print(vehicles)
	vehicles.to_csv('vehicles.csv', header=False, index=False)
	return vehicles

def choose_point(all_positions, mn, mx):
	point = (div_line, random.randint(mn, mx))
	while point in all_positions:
		point = (div_line, random.randint(mn, mx))
	all_positions.append(point)
	return point

def gen_machines(tasks):
	all_positions = [(int(row['x']),int(row['y'])) for _,row in tasks.iterrows()]
	max_min_0 = (max(all_positions)[0], min(all_positions)[0])
	max_min_1 = (max(all_positions)[1], min(all_positions)[1])
	mx = max(max_min_0[0], max_min_1[0])
	mn = min(max_min_0[1], max_min_1[1])
	spd = 0.1 # fixed by now

	# the first machine always attends all islands
	pt = choose_point(all_positions, mn, mx)
	machines = [[0, 0, 1, pt[0], pt[1], spd]]
	for i in range(1,n_machines):
		lz = 0
		hz = 1
		pt = choose_point(all_positions, mn, mx)
		machines.append([i, lz, hz, pt[0], pt[1], spd])

	machines = pd.DataFrame(machines, columns=['id', 'lz', 'hz', 'x', 'y', 'spd'])
	# print(machines)
	machines.to_csv('machines.csv', header=False, index=False)
	return machines


def gen_inst_files(filename, group, new_group):
	ifile = open(group+'/'+filename, 'r')
	inst_lines = ifile.read().splitlines()
	for i in range(len(inst_lines)):
		inst_lines[i] = inst_lines[i].split('\t')

	os.chdir(new_group)
	if not os.path.isdir(filename[:-4]):
		os.mkdir(filename[:-4])
	os.chdir(filename[:-4])

	vehicles = gen_vehicles(int(inst_lines[0][0]), int(inst_lines[0][1]))
	tasks = gen_tasks(inst_lines)
	machines = gen_machines(tasks)

	os.chdir('../../')


random.seed(0)
group = 'pdp_100'
n_machines = 3
new_group = group[:3]+'tw-se_2'+group[3:]
if not os.path.isdir(new_group):
	os.mkdir(new_group)

filenames = os.listdir(group)
for filename in filenames:
	gen_inst_files(filename, group, new_group)
	# break
