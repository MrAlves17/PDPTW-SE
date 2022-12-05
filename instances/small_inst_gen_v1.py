import os
import pandas as pd
import np
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



def gen_tasks(n_tasks):
	col_names = ['task_no', 'x', 'y', 'z', 'dem', 'earl', 'lat', 'servt', 'pid', 'did']
	tasks = []
	for i in range(n_tasks):
		tasks.append(gen_task())
	tasks = pd.DataFrame(tasks[1:], columns=col_names)
	x_values = [int(tasks['x'][i]) for i in range(len(tasks['x']))]
	global div_line
	div_line = math.ceil((max(x_values)+min(x_values))/2)
	tasks.insert(3, 'z', gen_z_values(tasks))
	# print(tasks)
	tasks.to_csv('tasks.csv', header=False, index=False)
	return tasks

def choose_capacity(a, b, k):
	return np.random.randint(1,k)*a + b

def gen_vehicles(n_vehicles):
	vehicles = []
	for i in range(n_vehicles):
		vehicles.append([i, choose_capacity(40, 80, 3)])

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
	os.chdir(new_group)
	if not os.path.isdir(filename[:-4]):
		os.mkdir(filename[:-4])
	os.chdir(filename[:-4])

	vehicles = gen_vehicles(5)
	tasks = gen_tasks(inst_lines)
	machines = gen_machines(tasks)

	os.chdir('../../')

np.random.seed(0)
n_machines = 2
new_group = group[:3]+'tw-se_1_10'
if not os.path.isdir(new_group):
	os.mkdir(new_group)

for filename in filenames:
	gen_inst_files(filename, group, new_group)
	# break
