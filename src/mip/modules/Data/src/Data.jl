module Data

using Infinity

struct InstanceData
	name
	vehicles
	tasks
	machines
	refs
	V
	V_p
	V_d
	Vprime
	q
	K
	Q
	d
	A 
	A_m
	A_s
	H
	H_e
	d_bar
	f
	O
	n
	s
end

struct Vehicle
	id::Int64
	cap::Int64
	Vehicle(l) = new(parse(Int64,l[1]), parse(Int64,l[2]))
end

struct Task
	id
	x
	y
	z
	dem
	earl
	lat
	servt
	pid
	did
	Task(l) = new(parse(Int64,l[1]), parse(Int64,l[2]), parse(Int64,l[3]), parse(Int64,l[4]), parse(Int64,l[5]), parse(Int64,l[6]), parse(Int64,l[7]), parse(Int64,l[8]), parse(Int64,l[9]), parse(Int64,l[10]))
end

struct Machine
	id
	lz
	hz
	x
	y
	spd
	Machine(l) = new(parse(Int64,l[1]), parse(Int64,l[2]), parse(Int64,l[3]), parse(Int64,l[4]), parse(Int64,l[5]), parse(Float64,l[6]))
end 

export InstanceData, readData, Vehicle, Task, Machine

function euclidean_dist(t1::Task, t2)
	return sqrt((t1.x - t2.x)^2 + (t1.y - t2.y)^2)
end # function euclidean_dist

function readData(instanceFile, params)

	println("Running Data.readData with file $(instanceFile)")
	name = basename(instanceFile[1:length(instanceFile)-1])
	println(name)
	vehicles = instanceFile * "vehicles.csv"
	tasks = instanceFile * "tasks.csv"
	machines = instanceFile * "machines.csv"

	f_vehicles = open(vehicles)
	f_tasks = open(tasks)
	f_machines = open(machines)

	fText_vehicles = read(f_vehicles, String)
	fText_tasks = read(f_tasks, String)
	fText_machines = read(f_machines, String)

	list_vehicles = split(fText_vehicles, '\n')
	list_tasks = split(fText_tasks, '\n')
	list_machines = split(fText_machines, '\n')
	
	vehicles = Any[]
	for i in 1:length(list_vehicles)-1
		splited = split(list_vehicles[i],',')
		push!(vehicles, Vehicle(splited))
	end

	tasks = Any[]
	for i in 1:length(list_tasks)-1
		splited = split(list_tasks[i],',')
		push!(tasks, Task(splited))
	end

	machines = Any[]
	for i in 1:length(list_machines)-1
		splited = split(list_machines[i],',')
		push!(machines, Machine(splited))
	end

	# With these lists we can access pickup and delivery tasks in order
	# like: First Request: 	<tasks[refs[1]].id, tasks[refs[n+1]].id, tasks[refs[1]].dem>
	#					 	<v_1, v_{n+1}, q_1>
	refs = Any[]
	push!(refs, 1)
	for cust in tasks
		if cust.dem > 0
			push!(refs, cust.id+1)
		end
		if length(refs) == params.cutoff+1
			break
		end
	end
	n = length(refs)-1
	for pid in refs[2:n+1]
		push!(refs, tasks[pid].did+1)
	end
	push!(refs, 1)
	println(refs)
	# println(refs)

	V = Any[]
	for i in 1:2*n+1
		push!(V, i)
	end
	println(V)

	V_p = Any[]
	for i in 2:length(refs[2:n+1])+1
		push!(V_p, i)
	end
	println(V_p)

	V_d = Any[]
	for i in 2:length(refs[n+2:length(refs)])
		push!(V_d, i+length(refs[2:n+1]))
	end
	println(V_d)

	Vprime = copy(V)
	push!(Vprime, length(V)+1)

	println(Vprime)

	A = Any[]
	for i in V[2:length(V)]
		for j in V[2:length(V)]
			if i != j # add to article
				push!(A, (i,j))
			end
		end
	end

	for j in V_p
		push!(A, (1,j))
	end
	push!(A, (1, length(Vprime)))

	for i in V_d
		push!(A, (i,length(Vprime)))
	end
	# println()
	# println(A)
	# println()

	q = Any[]
	for i in V
		push!(q, tasks[refs[i]].dem)
	end
	# println(q)

	K = Any[]
	for i in 1:length(vehicles)
		push!(K, i)
	end
	# println(K)

	Q = Any[]
	for k in K
		push!(Q, vehicles[k].cap)
	end
	# println(Q)

	d = Any[]
	for i in Vprime
		push!(d,Any[])
		for j in Vprime
			push!(d[i], Any[])
			for k in K
				if i != j
					push!(d[i][j], euclidean_dist(tasks[refs[i]], tasks[refs[j]]))
				else
					push!(d[i][j], ???)
				end
			end
		end
	end

	A_m = Any[]
	for (i,j) in A
		if tasks[refs[i]].z != tasks[refs[j]].z
			push!(A_m, (i,j))
		end
	end
	# println(A_m)

	A_s = Any[]
	for (i,j) in A
		if tasks[refs[i]].z == tasks[refs[j]].z
			push!(A_s, (i,j))
		end
	end
	# println(A_s)

	H = Any[]
	for i in 1:length(machines)
		push!(H, i)
	end
	# println(H)

	H_e = Dict()
	for (i,j) in A_m
		H_e[(i,j)] = Any[]
		for h in H
			if machines[h].lz <= tasks[refs[i]].z && machines[h].hz >= tasks[refs[i]].z && machines[h].lz <= tasks[refs[j]].z && machines[h].hz >= tasks[refs[j]].z
				push!(H_e[(i,j)], h)
			end
		end
	end

	# symmetrical 
	infty = 99999999
	d_bar = Any[] 
	for i in Vprime
		push!(d_bar,Any[])
		for h in H
			push!(d_bar[i], Any[])
			for k in K
				if tasks[refs[i]].z >= machines[h].lz && tasks[refs[i]].z <= machines[h].hz
					push!(d_bar[i][h], euclidean_dist(tasks[refs[i]], machines[h]))
				else
					push!(d_bar[i][h], infty)
				end
			end
		end
	end

	f = Any[]
	for i in Vprime
		push!(f, Any[])
		for h in H
			if machines[h].lz <= tasks[refs[i]].z <= machines[h].hz
				push!(f[i], tasks[refs[i]].z)
			else
				push!(f[i], -1)
			end

		end
	end


	O = Dict{Tuple{Int64,Int64,Int64}, Float64}()
	for i in Vprime
		for j in Vprime
			for h in H
				if f[i][h] != -1 && f[j][h] != -1
					O[(f[i][h],f[j][h], h)] = abs(f[i][h] - f[j][h])/machines[h].spd
				else 
					O[(f[i][h],f[j][h], h)] = infty
				end
			end
		end
	end
	println(O)

	s = Any[]
	for i in Vprime
		push!(s, tasks[refs[i]].servt)
	end

	inst = InstanceData(name, vehicles, tasks, machines, refs, V, V_p, V_d, Vprime, q, K, Q, d, A, A_m, A_s, H, H_e, d_bar, f, O, n, s)
	for i in inst.refs
		println(inst.tasks[i])
	end
	return inst
end # function readData()

end # module Data
