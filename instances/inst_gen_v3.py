import os
import pandas as pd
import numpy as np
import math

def gen_z_values(tasks):
	z = []
	for _,row in tasks.iterrows():
		if int(row['x']) <= div_line:
			z.append(0)
		else:
			z.append(1)

	return z

def gen_task_lc(cluster, i, n_requests, delivery):
	x_t = min(max(cluster['x'] + np.random.randint(-2,2)*3,0),99)
	y_t = min(max(cluster['y'] + np.random.randint(-2,2)*3,0),99)
	z_t = cluster['z']

	dem = np.random.randint(1,4)*10
	earl = np.random.randint(0,1440-150)
	lat = np.random.randint(earl+30, 1440-100)
	servt = 90
	if delivery:
		task_no = n_requests+i+1
		pid = i+1
		did = 0
	else:
		task_no = i+1
		pid = 0
		did = n_requests+i+1


	task = [task_no, x_t, y_t, z_t, dem, earl, lat, servt, pid, did]
	# print(task)
	return task

def gen_task_lr(i, n_requests, delivery):
	x_t = np.random.randint(1, 33)*3
	y_t = np.random.randint(1, 33)*3
	z_t = np.random.randint(0,2)

	dem = np.random.randint(1,4)*10
	earl = np.random.randint(0,1440-150)
	lat = np.random.randint(earl+30, 1440-100)
	servt = 90
	if delivery:
		task_no = n_requests+i+1
		pid = i+1
		did = 0
	else:
		task_no = i+1
		pid = 0
		did = n_requests+i+1


	task = [task_no, x_t, y_t, z_t, dem, earl, lat, servt, pid, did]
	# print(task)
	return task

def gen_depot():
	# 0,35,35,0,0,0,230,0,0,0
	task_no = 0
	x_t = np.random.randint(13, 18)*3
	y_t = np.random.randint(13, 18)*3
	z_t = np.random.randint(0, 2)

	dem = 0
	earl = 0
	lat = 1440
	servt = 0
	pid = 0
	did = 0

	task = [task_no, x_t, y_t, z_t, dem, earl, lat, servt, pid, did]
	# print(task)
	return task


def gen_tasks(n_tasks, t_inst):
	n_requests = n_tasks//2
	col_names = ['task_no', 'x', 'y', 'z', 'dem', 'earl', 'lat', 'servt', 'pid', 'did']
	tasks = []

	tasks.append(gen_depot())

	if t_inst == "lc":
		n_clusters = math.floor(math.sqrt(n_requests))
		for type_task in range(2):
			created = 0
			for c in range(n_clusters):
				cluster = {
					'x' : np.random.randint(1, 33)*3,
					'y' : np.random.randint(1, 33)*3,
					'z' : np.random.randint(0, 2)
				}
				for i in range(c*(n_requests//n_clusters),(c+1)*(n_requests//n_clusters)):
					tasks.append(gen_task_lc(cluster, i, n_requests, type_task))
					created+=1

				while created < n_requests and c == n_clusters-1:
					tasks.append(gen_task_lc(cluster, created, n_requests, type_task))
					created+=1
	elif t_inst == 'lr':
		for type_task in range(2):
			created = 0
			for i in range(n_requests):
				tasks.append(gen_task_lr(i, n_requests, type_task))
	elif t_inst == "lrc":
		n_clusters = math.floor(math.sqrt(n_requests))//2

		for type_task in range(2):
			created = 0
			for c in range(n_clusters):
				cluster = {
					'x' : np.random.randint(1, 33)*3,
					'y' : np.random.randint(1, 33)*3,
					'z' : np.random.randint(0, 2)
				}
				for i in range(c*(n_requests//(2*n_clusters)),(c+1)*(n_requests//(2*n_clusters))):
					tasks.append(gen_task_lc(cluster, i, n_requests, type_task))
					created+=1

			while created < n_requests:
				tasks.append(gen_task_lr(created, n_requests, type_task))
				created += 1


	tasks = pd.DataFrame(tasks, columns=col_names)
	print(tasks)
	tasks.to_csv('tasks.csv', header=False, index=False)
	return tasks

def choose_capacity(a, b, k):
	return np.random.randint(1,k+1)*a + b

def gen_vehicles(n_vehicles):
	vehicles = []
	for i in range(n_vehicles):
		vehicles.append([i, choose_capacity(40, 80, 3)])

	vehicles = pd.DataFrame(vehicles, columns=['v_no', 'cap'])
	# print(vehicles)
	vehicles.to_csv('vehicles.csv', header=False, index=False)
	return vehicles

def choose_point():
	point = (np.random.randint(13,18)*3, np.random.randint(1,33)*3)
	return point

def gen_machines(tasks):
	spd = 0.1 # fixed by now

	# the first machine always attends all islands
	pt = choose_point()
	machines = [[0, 0, 1, pt[0], pt[1], spd]]
	for i in range(1,n_machines):
		lz = 0
		hz = 1
		pt = choose_point()
		machines.append([i, lz, hz, pt[0], pt[1], spd])

	machines = pd.DataFrame(machines, columns=['id', 'lz', 'hz', 'x', 'y', 'spd'])
	# print(machines)
	machines.to_csv('machines.csv', header=False, index=False)
	return machines

def gen_inst_files(group):
	type_inst = ["lc", "lr", "lrc"]
	for tp in type_inst:
		for j in range(1,12+1):
			inst_name = tp+str(100+j)
			os.chdir(group)
			if not os.path.isdir(inst_name):
				os.mkdir(inst_name)
			os.chdir(inst_name)

			vehicles = gen_vehicles(5) 
			tasks = gen_tasks(10, tp)
			machines = gen_machines(tasks)

			os.chdir('../../')

np.random.seed(0)
n_machines = 3
new_group = 'pdptw-se_1_10'
if not os.path.isdir(new_group):
	os.mkdir(new_group)

gen_inst_files(new_group)