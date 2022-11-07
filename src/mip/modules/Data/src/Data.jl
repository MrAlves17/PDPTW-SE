module Data

struct InstanceData
	vehicles
	customers
	machines
	pickup_refs
	deliver_refs
	V
	V_p
	V_d
end

struct Vehicle
	id
	cap
	Vehicle(l) = new(parse(Int64,l[1]), parse(Int64,l[2]))
end

struct Customer
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
	Customer(l) = new(parse(Int64,l[1]), parse(Int64,l[2]), parse(Int64,l[3]), parse(Int64,l[4]), parse(Int64,l[5]), parse(Int64,l[6]), parse(Int64,l[7]), parse(Int64,l[8]), parse(Int64,l[9]), parse(Int64,l[10]))
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
export InstanceData, readData

function readData(instanceFile)

	println("Running Data.readData with file $(instanceFile)")
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

	customers = Any[]
	for i in 1:length(list_tasks)-1
		splited = split(list_tasks[i],',')
		push!(customers, Customer(splited))
	end

	machines = Any[]
	for i in 1:length(list_machines)-1
		splited = split(list_machines[i],',')
		push!(machines, Machine(splited))
	end

	
	pickup_refs = Any[]
	deliver_refs = Any[]
	for cust in customers
		if cust.dem > 0
			push!(pickup_refs, cust.id+1)
		end
	end
	for pid in pickup_refs
		push!(deliver_refs, customers[pid].did+1)
	end

	V = Any[]
	for i in 0:(length(customers)-1)
		push!(V, i)
	end

	V_p = Any[]
	for i in 1:length(pickup_refs)
		push!(V_p, i)
	end

	V_d = Any[]
	for i in 1:length(deliver_refs)
		push!(V_d, i+length(pickup_refs))
	end

	Vprime = V
	push!(Vprime, length(V))

	A = Any[]
	for i in V_p
		for j in V_d
			push!(A, (i,j))
		end
	end

	for j in V_p
		push!(A, (0,j))
	end
	push!(A, (0, length(V)))

	for i in V_d
		push!(A, (i,length(V)))
	end

	println(A)

	inst = InstanceData(vehicles, customers, machines, pickup_refs, deliver_refs, V, V_p, V_d, Vprime)
	
	return inst
end # function readData()

end # module Data
