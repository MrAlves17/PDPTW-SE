module Formulations

using JuMP
using Gurobi
#using CPLEX
using Data
using Parameters
using Infinity

struct Solution
	routes
	timesk
	timesh
	arcsh
end

export meloFormulation

epsilon = 0.000001

function meloFormulation(inst::InstanceData, params::ParameterData)
	println("Running Formulations.meloFormulation")

	if params.solver == "Gurobi"
		model = Model(Gurobi.Optimizer)
		set_optimizer_attribute(model, "TimeLimit", params.maxtime)
	else
		println("No solver selected")
		return 0
	end

	### Defining variables ###

	M = 2*inst.tasks[1].lat+1

	# Routing variables

	@variable(model, x[i=inst.Vprime,j=inst.Vprime,k=inst.K; (i,j) in inst.A], binary = true)
	@variable(model, z[i=inst.Vprime,k=inst.K] >= 0)
	
	# Scheduling variables

	@variable(model, t[i=inst.V] >= 0)
	@variable(model, C[k=inst.K] >= 0)
	@variable(model, phi[i=inst.Vprime, j=inst.Vprime, h=inst.H; (i,j) in inst.A_m], binary = true)
	@variable(model, gamma[i=inst.Vprime, j=inst.Vprime, iprime=inst.Vprime, jprime=inst.Vprime, h=inst.H; ((i,j) in inst.A_m) && ((iprime, jprime) in inst.A_m) && (i,j) != (iprime,jprime)], binary = true)
	@variable(model, alpha[i=inst.Vprime, j=inst.Vprime, h=inst.H; (i,j) in inst.A_m] >= 0)

	### Routing Constraints ###

	
	# c1
	for k in inst.K
		sumX = sum(x[1,j,k] for j in inst.V_p)
		sumX += x[1,2*inst.n+2,k]
		@constraint(model, sumX == 1, base_name = "c1")
	end

	# c2
	for k in inst.K
		for i in inst.V[2:length(inst.V)]
			sum1 = sum(x[j,i,k] for (j,p) in inst.A if p == i)
			sum2 = sum(x[i,j,k] for (p,j) in inst.A if p == i)

			@constraint(model, sum1 - sum2 == 0, base_name = "c2")
		end
	end

	# c3
	for k in inst.K
		sumX = sum(x[j,2*inst.n+2, k] for j in inst.V_d)
		sumX += x[1,2*inst.n+2, k]

		@constraint(model, sumX == 1, base_name = "c3")
	end

	# c4
	for i in inst.V[2:length(inst.V)]
		sumX = AffExpr(0)
		for k in inst.K
			for (j,p) in inst.A
				if p == i
					add_to_expression!(sumX, x[j,i,k])
				end
			end
		end
		@constraint(model, sumX == 1, base_name="c4")
	end

	# c5
	for k in inst.K
		for i in inst.V_p
			sum1 = AffExpr(0)
			for (j,p) in inst.A
				if p == i
					add_to_expression!(sum1, x[j,i,k])
				end
			end

			sum2 = AffExpr(0)
			for (j,p) in inst.A
				if p == inst.n+i
					add_to_expression!(sum2, x[j,inst.n+i,k])
				end
			end

			@constraint(model, sum1 == sum2, base_name="c5")
		end
	end

	# c6
	for k in inst.K
		@constraint(model, z[1,k] == 0, base_name = "c6")
	end

	# c7
	for k in inst.K
		for (i,j) in inst.A
			@constraint(model, z[j,k] >= z[i,k] + inst.q[i] - M*(1-x[i,j,k]), base_name = "c7")
		end
	end

	# c8
	for k in inst.K
		for i in inst.V[2:length(inst.V)]
			sumX = AffExpr(0)
			for (j,p) in inst.A
				if p == i
					add_to_expression!(sumX, x[j,i,k])
				end
			end

			@constraint(model, z[i,k] <= min(inst.Q[k], max(0, inst.Q[k] + inst.q[i]))*sumX, base_name = "c8")
		end
	end

	# c9
	for k in inst.K
		for i in inst.V_p
			sumX = AffExpr(0)
			for (j,p) in inst.A
				if p == i
					add_to_expression!(sumX, x[j,i,k])
				end
			end

			@constraint(model, z[i,k] >= inst.q[i]*sumX, base_name="c9")
		end
	end

	println("Finished Routing constraints")
	# # ### Scheduling constraints ###

	# c12
	for k in inst.K
		for (i,j) in inst.A
			if j in inst.V
				@constraint(model, t[j] >= t[i] + inst.s[i] + inst.d[i][j][k] - M*(1-x[i,j,k]), base_name = "c12")
			end
		end
	end

	# c13
	for i in inst.V_p
		@constraint(model, t[i] + inst.s[i] <= t[inst.n+i], base_name="c13")
	end

	# c14
	for i in inst.V[2:length(inst.V)]
		@constraint(model, inst.tasks[inst.refs[i]].earl <= t[i] <= inst.tasks[inst.refs[i]].lat, base_name = "c14")
	end

	# c15
	fix(t[1], 0; force = true)

	# c16
	for (i,j) in inst.A_m
		sum1 = AffExpr(0)
		for h in inst.H
			add_to_expression!(sum1, phi[i,j,h])
		end

		sum2 = AffExpr(0)
		for k in inst.K
			add_to_expression!(sum2, x[i,j,k])
		end

		@constraint(model, sum1 == sum2, base_name = "c16")
	end

	# c17
	for h in inst.H
		for k in inst.K
			for (i,j) in inst.A_m
				@constraint(model, alpha[i,j,h] >= t[i] + inst.s[i] + inst.d_bar[i][h][k] - M*(1-phi[i,j,h]), base_name = "c17")
			end
		end
	end

	# c18
	for h in inst.H
		for k in inst.K
			for (i,j) in inst.A_m
				if j in inst.V
					@constraint(model, t[j] >= alpha[i,j,h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.d_bar[j][h][k] - M*(2-phi[i,j,h]-x[i,j,k]), base_name = "c18")
				end
			end
		end
	end

	# c19
	for h in inst.H
		for (i,j) in inst.A_m
			for (iprime, jprime) in inst.A_m
				if (i,j) != (iprime, jprime)
					@constraint(model, gamma[i,j,iprime,jprime,h] + gamma[iprime,jprime,i,j,h] >= phi[i,j,h] + phi[iprime, jprime, h] - 1, base_name = "c19")
				end
			end
		end
	end

	# c20
	for h in inst.H
		for (i,j) in inst.A_m
			for (iprime, jprime) in inst.A_m
				if (i,j) != (iprime, jprime)
					@constraint(model, gamma[i,j,iprime,jprime,h] + gamma[iprime,jprime,i,j,h] <= 1 , base_name = "c20")
				end
			end
		end
	end

	# c21
	for h in inst.H
		for (i,j) in inst.A_m
			for (iprime, jprime) in inst.A_m
				if (i,j) != (iprime, jprime)
					@constraint(model, 2*gamma[i,j,iprime,jprime,h] <= phi[i,j,h] + phi[iprime,jprime,h], base_name = "c21")
				end
			end
		end
	end

	# c22
	for h in inst.H
		for (i,j) in inst.A_m
			for (iprime, jprime) in inst.A_m
				if (i,j) != (iprime, jprime)
					@constraint(model, alpha[iprime,jprime,h] >= alpha[i,j,h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.O[(inst.f[j][h], inst.f[iprime][h], h)] - M*(1 - gamma[i,j,iprime,jprime,h]), base_name = "c22")
				end
			end
		end
	end

	# c23
	for k in inst.K
		for (i,p) in inst.A
			if p == 2*inst.n+2
				@constraint(model, C[k] >= t[i] + inst.s[i] + inst.d[i][2*inst.n+2][k] - M*(1-x[i,2*inst.n+2,k]), base_name = "c23")
			end
		end
	end

	# c24
	for h in inst.H 
		for k in inst.K
			for (i,p) in inst.A_m
				if p == 2*inst.n+2
					@constraint(model, C[k] >= alpha[i,2*inst.n+2,h] + inst.O[(inst.f[i][h],inst.f[2*inst.n+2][h],h)] + inst.d_bar[2*inst.n+2][h][k] - M*(2-phi[i,2*inst.n+2,h]-x[i,2*inst.n+2,k]), base_name = "c24")
				end
			end
		end
	end

	# c25
	for k in inst.K
		@constraint(model, C[k] <= inst.tasks[inst.refs[2*inst.n+2]].lat, base_name="c25")
	end
	println("Finished Scheduling constraints")


	# ### Objective function ###

	# c30
	@objective(model, Min, sum(C))
	println("Finished Objective function")
	# write_to_file(model,"modelo.lp")
	# println("Model file created")


	t1 = time_ns()
	println("starting")
	status = optimize!(model)
	println("final")
	t2 = time_ns()
	elapsedtime = (t2-t1)/1.0e9

	opt = 0
	if termination_status(model) == OPTIMAL
	    println("Solution is optimal")
	    opt = 1
	elseif termination_status(model) == TIME_LIMIT && has_values(model)
	    println("Solution is suboptimal due to a time limit, but a primal solution is available")
	else
	    println("The model was not solved correctly.")
	    return
	end
	println("  objective value = ", objective_value(model))

	println(status)
	bestsol = sum(value.(C))
	bestbound = objective_bound(model)
	# numnodes = node_count(model)
	time = solve_time(model)
	gap = 100*(bestsol-bestbound)/bestsol



	open("saida.txt","a") do f
		write(f,";bestsol=$(bestsol);time=$(time);gap=$(gap)\n")
		# write(f,";$(x);$(value.(x));$(y);$(value.(y));$(p);$(value.(p));$(value.(u));\n")
	end

	x = value.(x)
	z = value.(z)
	t = value.(t)
	C = value.(C)
	phi = value.(phi)
	gamma = value.(gamma)
	alpha = value.(alpha)
	sol = createSolutionMelo(inst,x,z,t,C,phi,gamma,alpha)
	printDetailMeloFormulationSolution(inst,sol)
	saveMeloFormulationSolution(inst,sol)

	if validateSolution(inst, sol)
		println("Everything is awesome!")
	else
		println("Infeasible solution")
	end

end #function meloFormulation()

function createSolutionMelo(inst::InstanceData, x, z, t, C, phi, gamma, alpha)
	
	# # c12
	# println("c12,c12,c12,c12,c12,c12,c12,c12,c12,c12")
	# for k in inst.K
	# 	for (i,j) in inst.A
	# 		if j in inst.V
	# 			println(i," ",j, " ", k)
	# 			println(t[j], " >= ", t[i], " + ", inst.s[i], " + ", inst.d[i][j][k], " - M(1-",x[i,j,k], ")")
	# 			println()
	# 			# @constraint(model, t[j] >= t[i] + inst.s[i] + inst.d[i][j][k] - M*(1-x[i,j,k]), base_name = "c12")
	# 		end
	# 	end
	# end

	# # c13
	# println("c13,c13,c13,c13,c13,c13,c13,c13,c13,c13")
	# for i in inst.V_p
	# 	println(i)
	# 	println(t[i], " + ", inst.s[i], " <= ", t[inst.n+i])
	# 	println()
	# 	# @constraint(model, t[i] + inst.s[i] <= t[inst.n+i], base_name="c13")
	# end

	# # c14
	# println("c14,c14,c14,c14,c14,c14,c14,c14,c14,c14")
	# for i in inst.V[2:length(inst.V)]
	# 	println(i)
	# 	println(inst.tasks[inst.refs[i]].earl," <= ", t[i], " <= ", inst.tasks[inst.refs[i]].lat)
	# 	println()
	# 	# @constraint(model, inst.tasks[inst.refs[i]].earl <= t[i] <= inst.tasks[inst.refs[i]].lat, base_name = "c14")
	# end

	# # # c15
	# # fix(t[1], 0; force = true)

	# # c16
	# for (i,j) in inst.A_m
	# 	sum1 = 0
	# 	for h in inst.H
	# 		sum1 += phi[i,j,h]
	# 	end

	# 	sum2 = 0
	# 	for k in inst.K
	# 		sum2 += x[i,j,k]
	# 	end

	# 	println(sum1, "==", sum2)
	# 	println()
	# 	# @constraint(model, sum1 == sum2, base_name = "c16")
	# end

	# # c17
	# for h in inst.H
	# 	for k in inst.K
	# 		for (i,j) in inst.A_m
	# 			println(h," ", k, " ", (i,j))
	# 			println(alpha[i,j,h], " >= ", t[i], " + ", inst.s[i], " + ", inst.d_bar[i][h][k], " - M(1-", phi[i,j,h], ")")
	# 			println()
	# 			# @constraint(model, alpha[i,j,h] >= t[i] + inst.s[i] + inst.d_bar[i][h][k] - M*(1-phi[i,j,h]), base_name = "c17")
	# 		end
	# 	end
	# end

	# # c18
	# for h in inst.H
	# 	for k in inst.K
	# 		for (i,j) in inst.A_m
	# 			if j in inst.V
	# 				println(h, " ", k, " ", (i,j))
	# 				println(t[j], " >= ", alpha[i,j,h], " + ", inst.O[(inst.f[i][h], inst.f[j][h], h)], " + ", inst.d_bar[j][h][k], " - M(2-,", phi[i,j,h], "-", x[i,j,k])
	# 				println()
	# 				# @constraint(model, t[j] >= alpha[i,j,h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.d_bar[j][h][k] - M*(2-phi[i,j,h]-x[i,j,k]), base_name = "c18")
	# 			end
	# 		end
	# 	end
	# end

	# # c22
	# for h in inst.H
	# 	for (i,j) in inst.A_m
	# 		for (iprime, jprime) in inst.A_m
	# 			if (i,j) != (iprime, jprime)
	# 				println(h, " ", (i,j), " ", (iprime, jprime))
	# 				println(alpha[iprime,jprime,h], " >= ", alpha[i,j,h], " + ", inst.O[(inst.f[i][h], inst.f[j][h], h)], " + ", inst.O[(inst.f[j][h], inst.f[iprime][h], h)], " - M(1 - ", gamma[i,j,iprime,jprime,h], ")")
	# 				println()
	# 				# @constraint(model, alpha[iprime,jprime,h] >= alpha[i,j,h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.O[(inst.f[j][h], inst.f[iprime][h], h)] - M*(1 - gamma[i,j,iprime,jprime,h]), base_name = "c22")
	# 			end
	# 		end
	# 	end
	# end

	routes = Any[]
	timesk = Any[]
	timesh = Any[]
	arcsh = Any[]

	for k in inst.K
		push!(routes, Any[])
		push!(timesk, Any[])
		push!(timesh, Any[])
		i=1
		while i != length(inst.Vprime)
			push!(routes[k], i)
			push!(timesk[k], t[i])
			for j in inst.Vprime
				if (i,j) in inst.A && abs(x[i,j,k]-1) <= 0.1
					if (i,j) in inst.A_m
						for h in inst.H
							if abs(phi[i,j,h]-1) <= 0.1
								push!(timesh[k], (h, alpha[i,j,h]))
								push!(arcsh, (inst.tasks[inst.refs[i]].id,inst.tasks[inst.refs[j]].id,inst.machines[h].id))
								break
							end
						end
					end
					i = j
					break
				end
			end
		end

		push!(routes[k], i)
		push!(timesk[k], C[k])
	end

	sol = Solution(routes, timesk, timesh, arcsh)

	return sol

end # function createSolutionMelo()

function printTaskDetail(inst::InstanceData, task, tk, th=(0,0.0))
	println("\tid: ", task.id)
	println("\t\t(x,y,z): ", (task.x, task.y, task.z))
	println("\t\tdem: ", task.dem)
	println("\t\tearl: ", task.earl)
	println("\t\tlat: ", task.lat)
	println("\t\tservt: ", task.servt)
	println("\t\tpid: ", task.pid)
	println("\t\tdid: ", task.did)
	println("\t\ttk: ", tk)
	println("\t\t(h,th): ", th)
	println()
end # function printTaskDetail()


function printRouteDetail(inst::InstanceData, route, timek, timeh, k)
	zk = inst.tasks[inst.refs[route[1]]].z
	j = 0
	for i in 1:length(route)
		if zk != inst.tasks[inst.refs[route[i]]].z
			j+=1
			h = timeh[j][1]
			println("\tUsing Machine: ", h)
			if i != 1 
				println("\tTask ", inst.refs[route[i-1]]-1," -> Machine ",h,": ",inst.d_bar[route[i-1]][h][k])
				println("\tIsland ",zk," -> Island ",inst.tasks[inst.refs[route[i]]].z,": ", inst.O[(inst.f[route[i-1]][h],inst.f[route[i]][h], h)])
				println("\tMachine ",h," -> Task ",inst.refs[route[i]]-1,": ",inst.d_bar[route[i]][h][k])
				println()
			end
			printTaskDetail(inst, inst.tasks[inst.refs[route[i]]], timek[i], timeh[j])
		else
			if i != 1 
				println("\tTask ",inst.refs[route[i-1]]-1," -> Task ",inst.refs[route[i]]-1,": ",inst.d[route[i-1]][route[i]][k])
				println()
			end
			printTaskDetail(inst, inst.tasks[inst.refs[route[i]]], timek[i])
		end

		zk = inst.tasks[inst.refs[route[i]]].z
	end
end # function printRouteDetail()

function printDetailMeloFormulationSolution(inst::InstanceData, sol::Solution)
	for k in inst.K
		if length(sol.routes[k]) > 2
			println("Route ", k," :")
			printRouteDetail(inst, sol.routes[k], sol.timesk[k], sol.timesh[k], k)
			println()
		end
	end
	println(sol.arcsh)

end # function printDetailMeloFormulationSolution()

function saveMeloFormulationSolution(inst::InstanceData, sol::Solution)
	sol_filename = "solutions/solution_" * inst.name * ".txt"
	file = open(sol_filename, "w")
	write(file, uppercase(inst.name))
	write(file, '\n')
	for k in inst.K
		write(file, "Route " * string(k) * ": ")
		rt = sol.routes[k]
		th = sol.timesh[k]
		ih = 0
		for fid in 1:length(rt)
			write(file, string(inst.tasks[inst.refs[rt[fid]]].id) * " ")
			if fid < length(rt) && inst.tasks[inst.refs[rt[fid+1]]].z != inst.tasks[inst.refs[rt[fid]]].z
				ih += 1
				write(file, "M" * string(inst.machines[th[ih][1]].id) * " ")
			end
		end
		write(file, '\n')
	end
	close(file)
end # function saveMeloFormulationSolution()

mutable struct StateK
	t
	p
	h # 0 -> !machine; 1 -> task-machine; 2 -> machine-task
	ith
	l
end

mutable struct StateH
	t
	p
end

Base.copy(s::StateK) = StateK(s.t, s.p, s.h, s.ith, s.l)
Base.copy(s::StateH) = StateH(s.t, s.p)

function validateSolution(inst::InstanceData, sol::Solution)
	infeasibilities = 0
	tasks_visited = [Any[false, 0] for i in inst.Vprime]
	for k in inst.K
		rt = sol.routes[k]
		if rt[1] != 1
			println("Route doesn't start at depot")
			return false
		end
		tasks_visited[rt[1]] = Any[true, k]
		if rt[length(rt)] != length(inst.Vprime)
			println("Route doesn't end at depot (", rt[length(rt)], ") (", length(inst.Vprime))
			return false
		end
		tasks_visited[rt[length(rt)]] = Any[true, k]

		for i in 2:length(rt)-1
			if tasks_visited[rt[i]][1]
				println("Task was already done by vehicle ", tasks_visited[rt[i]][2])
				return false
			end
			if rt[i] > inst.n+1 # if delivery
				if tasks_visited[rt[i]-inst.n][2] == k && !tasks_visited[rt[i]-inst.n][1]
					println("Delivery task ", inst.tasks[inst.refs[rt[i]]].id, " was done before pickup", inst.tasks[inst.refs[rt[i]-inst.n]].id)
					return false
				end
				if rt[i] > inst.n+1 && tasks_visited[rt[i]-inst.n][2] != k && tasks_visited[rt[i]-inst.n][1]
					println("Pickup task ", inst.tasks[inst.refs[rt[i]-inst.n]].id, " was done by another vehicle (pv=",tasks_visited[rt[i]-inst.n][2], ") != (dv=", k, ")")
					return false
				end
			end
			tasks_visited[rt[i]] = Any[true, k]
		end
	end

	for i in inst.Vprime
		if !tasks_visited[i][1]
			println("Task ", inst.tasks[inst.refs[i]].id, " was not done")
			return false
		end
	end

	statesK = Any[StateK(0,1,0,0,0) for k in inst.K]
	statesH = Any[StateH(0,inst.machines[h].lz+1) for h in inst.H]
	vehiclesDepot = 0
	while  vehiclesDepot < length(inst.K)
		best_stk = StateK(9999999, 1, 0, 0, 0)
		best_sth = StateH(0,1)
		best_k = 0
		best_h = 0
		waitlists_h = Any[Any[] for h in inst.H]

		for k in inst.K
			th = sol.timesh[k]
			st = statesK[k]
			if st.h == 1
				h = th[st.ith][1]
				push!(waitlists_h[h], (st.t, k))
			end
		end

		for h in inst.H
			sort(waitlists_h[h])
		end
		# println(waitlists_h)

		for k in inst.K
			rt = sol.routes[k]
			tk = sol.timesk[k]
			th = sol.timesh[k]

			st = copy(statesK[k])
			sth = StateH(0,1)
			if st.p == length(rt)
				continue
			end

			pTask = inst.tasks[inst.refs[rt[st.p]]]
			aTask = inst.tasks[inst.refs[rt[st.p+1]]]
			
			if st.h == 1
				h = th[st.ith][1]
				sth = copy(statesH[h])
				for (t,k1) in waitlists_h[h]
					stk = statesK[k1]
					if k1 != k
						sth.t += inst.O[(inst.f[sth.p][h], inst.f[rt[stk.p]][h], h)]
						sth.t = max(sth.t, stk.t)
						sth.t += inst.O[(inst.f[rt[stk.p]][h], inst.f[rt[stk.p+1]][h], h)]
						sth.p = rt[stk.p+1]
					else 
						sth.t += inst.O[(inst.f[sth.p][h], inst.f[rt[stk.p]][h], h)]
						break
					end
				end
				st.t = max(st.t, sth.t)
				sth.t = st.t
				st.t += inst.O[(inst.f[rt[st.p]][h], inst.f[rt[st.p+1]][h], h)]
				sth.t += inst.O[(inst.f[rt[st.p]][h], inst.f[rt[st.p+1]][h], h)]
				sth.p = rt[st.p+1]
				st.h = 2
			elseif st.h == 2
				h = th[st.ith][1]
				st.t += inst.d_bar[rt[st.p+1]][h][k]
				st.t = max(st.t, aTask.earl)
				# if abs(tk[st.p+1]-st.t) >= epsilon
				# 	println("Arrived at (", tk[st.p+1], "), but should be (", st.t, ")")
				# 	return false
				# end
				if st.t > aTask.lat
					println("Start of service time (", st.t, ") after the time window closed (", aTask.lat, ")")  
					return false
				end
				st.t += aTask.servt
				st.l += aTask.dem
				if st.l > inst.vehicles[k].cap
					println("Vehicle exceeded its capacity: (", st.l, ") > (", inst.vehicles[k].cap, ")")
					return false
				end
				st.p += 1
				st.h = 0
			elseif aTask.z != pTask.z
				st.ith += 1
				h = th[st.ith][1]
				st.t += inst.d_bar[rt[st.p]][h][k]
				st.h = 1
			else
				st.t += inst.d[rt[st.p]][rt[st.p+1]][k]
				st.t = max(st.t, aTask.earl)
				# if abs(tk[st.p+1]-st.t) >= epsilon
				# 	println("Arrived at (", tk[st.p+1], "), but should be (", st.t, ")")
				# 	return false
				# end
				if st.t > aTask.lat
					println("Start of service time (", st.t, ") after the time window closed (", aTask.lat, ")")  
					return false
				end
				st.t += aTask.servt
				st.l += aTask.dem
				if st.l > inst.vehicles[k].cap
					println("Vehicle exceeded its capacity: (", st.l, ") > (", inst.vehicles[k].cap, ")")
					return false
				end
				if st.l < 0
					println("Vehicle ", k, " doesn't have the package to delivery")
					return false
				end
				st.p += 1
			end

			if st.t < best_stk.t
				best_stk = st
				best_k = k
				best_sth = sth
				if statesK[k].h == 1 || st.ith == 0 || st.ith == 1 && statesK[k].h == 0
					best_h = -1
				else
					best_h = th[st.ith][1]
				end
			end
		end

		statesK[best_k] = best_stk
		if best_h != -1
			statesH[best_h] = best_sth
		end
		if statesK[best_k].p == length(sol.routes[best_k])
			vehiclesDepot+=1
		end
		# println(statesK)
		# println(statesH)
	end

	# end
	if infeasibilities > 0
		return false
	end

	return true

end # function validateSolution()

end # module
