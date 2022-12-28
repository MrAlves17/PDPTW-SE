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

def gen_task(task_no, ):


def gen_tasks(n_tasks, t_inst):
	n_requests = n_tasks//2
	col_names = ['task_no', 'x', 'y', 'z', 'dem', 'earl', 'lat', 'servt', 'pid', 'did']
	tasks = []
	if t_inst == "lc":
		n_clusters = math.floor(math.log(n_requests))
		for c in range(n_clusters):
			x_c = np.random.randint(0, 100)
			y_c = np.random.randint(0, 100)
			z_c = np.random.randint(0, 1)
			for i in range(c*n_requests//n_clusters,(c+1)*n_requests//n_clusters-1):
				x_t = x_c + np.random.randint(-2,2)*5
				y_t = y_c + np.random.randint(-2,2)*5
				z_t = z_c

				dem = np.random.randint(1,4)*10
				earl = np.random.randint(0,1440-150)
				lat = np.random.randint(earl+30, 1440-100)
				servt = 90
				pid = 0
				did = n_requests+i

				task = [i+1, x_t, y_t, z_t, dem, earl, lat, servt, pid, did]
				tasks.push(task)

			# create the rest of the tasks for the last cluster
		





	for i in range(n_tasks):
		tasks.append(gen_task(i))
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

def gen_inst_files(group):
	type_inst = ["lc", "lr", "lrc"]
	for i in range(3):
		for j in range(1,12+1):
			inst_name = type_inst[i]+"_"+str(100+j)
			os.chdir(group)
			if not os.path.isdir(inst_name):
				os.mkdir(inst_name)
			os.chdir(inst_name)

			vehicles = gen_vehicles(5) 
			tasks = gen_tasks(10, type_inst[i])
			machines = gen_machines(tasks, type_inst[i])

			os.chdir('../../')

np.random.seed(0)
n_machines = 2
new_group = 'pdptw-se_1_10'
if not os.path.isdir(new_group):
	os.mkdir(new_group)

gen_inst_files(new_group)