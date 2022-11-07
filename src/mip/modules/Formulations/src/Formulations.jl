module Formulations

using JuMP
using Gurobi
#using CPLEX
using Data
using Parameters

struct Solution
	route
	routePrime
	time
	timePrime
end

export murrayFormulation, freitasFormulation

function murrayFormulation(inst::InstanceData, params::ParameterData)
	println("Running Formulations.murrayFormulation")

	if params.solver == "Gurobi"
		model = Model(Gurobi.Optimizer)
		set_optimizer_attribute(model, "TimeLimit", params.maxtime)
	else
		println("No solver selected")
		return 0
	end

	### Defining variables ###

	M = 1000

	@variable(model, x[i=inst.N0,j=inst.Nplus; j != i], binary = true)
	@variable(model, y[i=inst.N0, j=inst.C, k=inst.Nplus; j != i && (i,j,k) in inst.P], binary = true)
	@variable(model, 1 <= u[inst.Nplus] <= length(inst.C)+2)
	@variable(model, t[inst.N] >= 0)
	@variable(model, tprime[inst.N] >= 0)
	@variable(model, p[i=inst.N0, j=inst.C; j != i], binary = true)

	# ### Objective function ###

	# c1
	@objective(model, Min, sum(t[i]*0.00001 for i in inst.N0)+100000*t[length(inst.N)])
	# @objective(model, Min, t[length(inst.N)])

	# # ### Setup constraints ###

	# c2
	for j in inst.C
		sumX = sum(x[i,j] for i in inst.N0 if i != j)
		
		sumY = 0
		for i in inst.N0 
			if i != j
				for k in inst.Nplus 
					if (i,j,k) in inst.P
						sumY += y[i,j,k]
					end
				end
			end
		end

		@constraint(model, sumX + sumY == 1,base_name = "c2")
	end

	# c3
	@constraint(model, sum(x[1,j] for j in inst.Nplus) == 1,base_name = "c3")

	# c4
	@constraint(model, sum(x[i,length(inst.N)] for i in inst.N0) == 1,base_name = "c4")

	# c5
	for i in inst.C
		for j in inst.Nplus
			if i != j
				@constraint(model, u[i] - u[j] + 1 <= (length(inst.C)+2)*(1-x[i,j]),base_name = "c5")
			end
		end
	end

	# c6
	for j in inst.C
		sum1 = sum(x[i,j] for i in inst.N0 if i != j)

		sum2 = sum(x[j,k] for k in inst.Nplus if k != j)

		@constraint(model, sum1 == sum2,base_name = "c6")
	end

	# c7
	for i in inst.N0
		sumY = 0
		for j in inst.C 
			if i != j 
				for k in inst.Nplus 
					if (i,j,k) in inst.P
						sumY += y[i,j,k]
					end
				end
			end
		end
		if sumY != 0
			@constraint(model, sumY <= 1,base_name = "c7")
		end
	end

	# c8
	for k in inst.Nplus
		sumY = 0
		for i in inst.N0 
			if i != k 
				for j in inst.C 
					if (i,j,k) in inst.P
						sumY += y[i,j,k]
					end
				end
			end
		end

		if sumY != 0
			@constraint(model, sumY <= 1,base_name = "c8")
		end
	end

	# c9
	for i in inst.C
		for j in inst.C
			if i != j
				for k in inst.Nplus
					if (i,j,k) in inst.P
						sum1 = sum(x[h,i] for h in inst.N0 if h != i)

						sum2 = sum(x[l,k] for l in inst.C if l != k)

						@constraint(model, 2*y[i,j,k] <= sum1 + sum2,base_name = "c9")
					end
				end
			end
		end
	end

	# c10
	for j in inst.C
		for k in inst.Nplus
			if (1,j,k) in inst.P
				sumX = sum(x[h,k] for h in inst.N0 if h != k)

				@constraint(model, y[1,j,k] <= sumX,base_name = "c10")
			end
		end
	end

	# c11
	for i in inst.C
		for k in inst.Nplus
			if k != i
				sumY = 0
				for j in inst.C 
					if (i,j,k) in inst.P
						sumY += y[i,j,k]
					end
				end

				@constraint(model, u[k] - u[i] >= 1 - (length(inst.C)+2)*(1-sumY),base_name = "c11")
			end
		end
	end

	# c12
	for i in inst.C
		sumY = sum(y[i,j,k] for j in inst.C
								if j != i
									for k in inst.Nplus
										if (i,j,k) in inst.P)

		@constraint(model, tprime[i] >= t[i] - M*(1-sumY),base_name = "c12")
	end

	# c13
	for i in inst.C
		sumY = sum(y[i,j,k] for j in inst.C
								if j != i
									for k in inst.Nplus
										if (i,j,k) in inst.P)

		@constraint(model, tprime[i] <= t[i] + M*(1-sumY),base_name = "c13")
	end

	# c14
	for k in inst.Nplus
		sumY = sum(y[i,j,k] for i in inst.N0
								if i != k
									for j in inst.C
										if (i,j,k) in inst.P)

		@constraint(model, tprime[k] >= t[k] - M*(1-sumY),base_name = "c14")
	end

	# c15
	for k in inst.Nplus
		sumY = sum(y[i,j,k] for i in inst.N0
								if i != k
									for j in inst.C
										if (i,j,k) in inst.P)

		@constraint(model, tprime[k] <= t[k] + M*(1-sumY),base_name = "c15")
	end

	# c16
	for h in inst.N0
		for k in inst.Nplus
			if h != k
				sum1 = 0

				# # (LAUNCH from previous node)
				# # (LAUNCH from depot is added)
				# for l in inst.C
				# 	if l != h
				# 		for m in inst.Nplus
				# 			if (h,l,m) in inst.P
				# 				sum1 += y[h,l,m]
				# 			end
				# 		end
				# 	end
				# end

				# (LAUNCH from current node)
				for l in inst.C
					if l != k
						for m in inst.Nplus
							if (k,l,m) in inst.P
								sum1 += y[k,l,m]
							end
						end
					end
				end

				sum2 = 0
				for i in inst.N0
					if i != k
						for j in inst.C
							if (i,j,k) in inst.P
								sum2 += y[i,j,k]
							end
						end
					end
				end

				@constraint(model, t[k] >= t[h] + inst.tau[h,k] + inst.s_l*(sum1) + inst.s_r*(sum2) - M*(1-x[h,k]),base_name = "c16")
			end
		end
	end

	# c17
	for j in inst.Cprime
		for i in inst.N0
			if i != j
				sumY = 0
				for k in inst.Nplus 
					if (i,j,k) in inst.P
						sumY += y[i,j,k]
					end
				end
				# (LAUNCH from current node)
				@constraint(model, tprime[j] >= tprime[i] + inst.tauprime[i,j] - M*(1-sumY),base_name = "c17")
				# (LAUNCH from previous node)
				# @constraint(model, tprime[j] >= tprime[i] + inst.s_l + inst.tauprime[i,j] - M*(1-sumY),base_name = "c17")
			end
		end
	end

	# c18
	for j in inst.Cprime
		for k in inst.Nplus
			if k != j

				sumY = 0
				for i in inst.N0 
					if (i,j,k) in inst.P
						sumY += y[i,j,k]
					end
				end

				# (LAUNCH from previous node)
				# @constraint(model, tprime[k] >= tprime[j] + inst.tauprime[j,k] + inst.s_r - M*(1-sumY),base_name = "c18")
				# (LAUNCH from current node)
				sum2 = 0
				for l in inst.C
					for m in inst.Nplus
						if k != m && (k,l,m) in inst.P
							sum2 += y[k,l,m]
						end
					end
				end

				@constraint(model, tprime[k] >= tprime[j] + inst.tauprime[j,k] + inst.s_r + inst.s_l*sum2 - M*(1-sumY),base_name = "c18")
			end
		end
	end

	# c19
	for k in inst.Nplus
		for j in inst.C
			if j != k
				for i in inst.N0
					if (i,j,k) in inst.P
						sum1 = AffExpr(0)
						for l in inst.C
							for m in inst.Nplus
								if k != m && (k,l,m) in inst.P
									add_to_expression!(sum1, y[k,l,m])
								end
							end
						end
						@constraint(model, (tprime[k] - inst.s_l*sum1) - tprime[i] <= inst.endurance + M*(1-y[i,j,k]),base_name = "c19")
					end
				end
			end
		end
	end

	# c20
	for i in inst.C
		for j in inst.C
			if i != j
				@constraint(model, u[i] - u[j] >= 1 - (length(inst.C)+2)*p[i,j],base_name = "c20")
			end
		end
	end

	# c21
	for i in inst.C
		for j in inst.C
			if i != j
				@constraint(model, u[i] - u[j] <= -1 + (length(inst.C)+2)*(1-p[i,j]),base_name = "c21")
			end
		end
	end

	# c22
	for i in inst.C
		for j in inst.C
			if i != j
				@constraint(model, p[i,j] + p[j,i] == 1,base_name = "c22")
			end
		end
	end

	# c23
	for i in inst.N0
		for k in inst.Nplus
			if i != k
				for l in inst.C
					if i != l && l != k
						sum1 = 0

						for j in inst.C 
							if j != l && (i,j,k) in inst.P
								sum1 += y[i,j,k]
							end
						end

						sum2 = 0
						for m in inst.C
							if i != m && k != m && l != m
								for n in inst.Nplus
									if i != n && k != n && (l,m,n) in inst.P
										sum2 += y[l,m,n]
									end
								end
							end
						end
				
						@constraint(model, tprime[l] >= tprime[k] - M*(3 - sum1 - sum2 - p[i,l]),base_name = "c23")
					end
				end
			end
		end
	end

	# c24
	fix(t[1], 0; force = true)

	# c25
	fix(tprime[1], 0; force = true)

	# c26
	for j in inst.C
		fix(p[1,j], 1; force = true)
	end

	# write_to_file(model,"modelo.lp")

	t1 = time_ns()
	status = optimize!(model)
	t2 = time_ns()
	elapsedtime = (t2-t1)/1.0e9

	bestsol = value.(t)[length(inst.N)]
	bestbound = objective_bound(model)
	# numnodes = node_count(model)
	time = solve_time(model)
	gap = 100*(bestsol-bestbound)/bestsol

        #println(status)
	opt = 0
	if status == :Optimal
		opt = 1
        end

	open("saida.txt","a") do f
		write(f,";bestsol=$(bestsol);time=$(time)\n")
		# write(f,";$(x);$(value.(x));$(y);$(value.(y));$(p);$(value.(p));$(value.(u));\n")
	end

	x_value = value.(x)
	y_value = value.(y)
	u_value = value.(u)
	t_value = value.(t)
	tprime_value = value.(tprime)
	p_value = value.(p)

	sol = createSolutionMurray(inst,value.(x),value.(y),value.(u),value.(t),value.(tprime),value.(p))
	printMurrayFormulationSolution(inst,sol)

	if validateSolution(inst, sol)
		println("Everything is awesome!")
	end

end #function MurrayFormulation()

function createSolutionMurray(inst::InstanceData, x, y, u, t, tprime, p)
	M = 1000

	# # c16
	# for h in inst.N0
	# 	for k in inst.Nplus
	# 		if h != k
	# 			sum1 = 0

	# 			for l in inst.C
	# 				if l != k
	# 					for m in inst.Nplus
	# 						if (k,l,m) in inst.P
	# 							sum1 += y[k,l,m]
	# 						end
	# 					end
	# 				end
	# 			end

	# 			sum2 = 0
	# 			for i in inst.N0
	# 				if i != k
	# 					for j in inst.C
	# 						if (i,j,k) in inst.P
	# 							sum2 += y[i,j,k]
	# 						end
	# 					end
	# 				end
	# 			end

	# 			println(h, " ", k)
	# 			println(t[h])
	# 			println(t[k])
	# 			println(inst.tau[h,k])
	# 			println(inst.s_l*(sum1))
	# 			println(inst.s_r*(sum2))
	# 			println(x[h,k])
	# 			# @constraint(model, t[k] >= t[h] + inst.tau[h,k] + inst.s_l*(sum1) + inst.s_r*(sum2) - M*(1-x[h,k]),base_name = "c16")
	# 		end
	# 	end
	# end

	# # c17
	# for j in inst.Cprime
	# 	for i in inst.N0
	# 		if i != j
	# 			sumY = 0
	# 			get_k = -1
	# 			for k in inst.Nplus 
	# 				if (i,j,k) in inst.P
	# 					if y[i,j,k] > 0
	# 						get_k = k
	# 					end
	# 					sumY += y[i,j,k]
	# 				end
	# 			end

	# 			println(i, ",", j, ",", get_k)
	# 			println("tprime[",i,"] = ",tprime[i])
	# 			println("tprime[",j,"] = ",tprime[j])
	# 			println("tauprime[",i,",",j,"] = ",inst.tauprime[i,j])
	# 			println("sumY = ", sumY)

	# 			println()
	# 			# @constraint(model, tprime[j] >= tprime[i] + inst.tauprime[i,j] - M*(1-sumY))
	# 		end
	# 	end
	# end
	# println("\n\n\n\n\n\n\n----------------------------------------------------\n\n\n\n\n\n\n")
	
	# # c18
	# for j in inst.Cprime
	# 	for k in inst.Nplus
	# 		if k != j
	# 			sumY = 0
	# 			for i in inst.N0 
	# 				if (i,j,k) in inst.P
	# 					sumY += y[i,j,k]
	# 				end
	# 			end

	# 			# @constraint(model, tprime[k] >= tprime[j] + inst.tauprime[j,k] + inst.s_r - M*(1-sumY),base_name = "c18")
	# 			sum2 = 0
	# 			for l in inst.C
	# 				for m in inst.Nplus
	# 					if k != m && (k,l,m) in inst.P
	# 						sum2 += y[k,l,m]
	# 					end
	# 				end
	# 			end

	# 			@constraint(model, tprime[k] >= tprime[j] + inst.tauprime[j,k] + inst.s_r + inst.s_l*sum2 - M*(1-sumY),base_name = "c18")
	# 		end
	# 	end
	# end

	# # c18
	# for j in inst.Cprime
	# 	for k in inst.Nplus
	# 		if k != j
	# 			sumY = 0
	# 			get_i = -1
	# 			for i in inst.N0 
	# 				if (i,j,k) in inst.P
	# 					if y[i,j,k] > 0
	# 						get_i = i
	# 					end
	# 					sumY += y[i,j,k]
	# 				end
	# 			end

	# 			sum2 = 0
	# 			for l in inst.C
	# 				for m in inst.Nplus
	# 					if k != m && (k,l,m) in inst.P
	# 						sum2 += y[k,l,m]
	# 					end
	# 				end
	# 			end

	# 			println(get_i, ",", j, ",", k)
	# 			println("tprime[",j,"] = ",tprime[j])
	# 			println("tprime[",k,"] = ",tprime[k])
	# 			println("tauprime[",j,",",k,"] = ",inst.tauprime[j,k])
	# 			println("sumY = ", sumY)
	# 			println("sum2 = ", sum2)
	# 			println()

	# 			# @constraint(model, tprime[k] >= tprime[j] + inst.tauprime[j,k] + inst.s_r - M*(1-sumY))
	# 		end
	# 	end
	# end

	# # c19
	# for k in inst.Nplus
	# 	for j in inst.C
	# 		if j != k
	# 			for i in inst.N0
	# 				if (i,j,k) in inst.P
	# 					println(i, ",", j, ",", k)
	# 					println("tprime[",j,"] = ",tprime[j])
	# 					println("tprime[",k,"] = ",tprime[k])
	# 					println("tauprime[",i,",",j,"] = ",inst.tauprime[i,j])
	# 					println("endurance = ", inst.endurance)
	# 					println("y[i,j,k] = ", y[i,j,k])
	# 					println()
	# 					# @constraint(model, tprime[k] - (tprime[j] - inst.tauprime[i,j]) <= inst.endurance + M*(1-y[i,j,k]))
	# 				end
	# 			end
	# 		end
	# 	end
	# end

	route = Any[]

	i=1
	while i != length(inst.N)
		push!(route, i-1)
		for j in inst.Nplus
			if i != j && x[i,j] > 0
				i = j
				break
			end
		end
	end
	push!(route, i-1)

	routePrime = Any[]
	if length(route) < length(inst.N)
		for i in inst.N0
			for j in inst.C
				for k in inst.Nplus
					if (i,j,k) in inst.P && y[i,j,k] > 0
						push!(routePrime, (i-1,j-1,k-1))
					end
				end
			end
		end
	end

	time = t
	timePrime = tprime

	sol = Solution(route, routePrime, time, timePrime)

	return sol

end # function createSolutionMurray()

function printMurrayFormulationSolution(inst::InstanceData, sol::Solution)
	
	for i in sol.route
		print(i,"(",sol.time[i+1],")->")
	end
	println()
	for i in sol.routePrime
		println(i)
	end

end # function printMurrayFormulationSolution()

function validateSolution(inst::InstanceData, sol::Solution)
	validated = true

	if sol.route[1] != 0 || sol.route[length(sol.route)] != 11
		println("[ERROR] Route doesn't start or end with depot")
		validated = false
	end

	if length(sol.route) + length(sol.routePrime) != 12
		println("[ERROR] Num. of customers visited: ", length(sol.route) + length(sol.routePrime))
		validated = false
	end

	c = Any[]
	for i in 1:length(sol.route)
		if sol.route[i] in c
			println("[ERROR] Customer ", sol.route[i], " was already visited ")
			validated = false
		else
			push!(c, sol.route[i])
		end
	end

	cprime = Any[]
	for i in 1:length(sol.routePrime)
		if sol.routePrime[i][2] in cprime || sol.routePrime[i][2] in sol.route
			println("[ERROR] Customer ", sol.routePrime[i][2], " was already visited")
			validated = false
		else
			push!(cprime, sol.routePrime[i][2])
		end
	end

	t=0
	tprime=0
	droneFlying = false
	droneFlight = (-1,-1,-1)
	droneAttended = 0
	
	# # (LAUNCH from previous node)
	# # (LAUNCH includes depot)
	# if abs(t-sol.time[1]) > 0.00001
	# 	println("[ERROR] t=",t," time[",sol.route[1],"]=", sol.time[sol.route[1]+1])
	# 	println("Time arrival calculated is different from received")
	# 	validated = false
	# end

	# for i in 2:length(sol.route)
	# 	println("Estou em ", sol.route[i-1], " e indo para ", sol.route[i])
	# 	println("DIST -> ", inst.tau[sol.route[i-1]+1,sol.route[i]+1])
	# 	t = t + inst.tau[sol.route[i-1]+1,sol.route[i]+1]
	# 	if !droneFlying
	# 		for l in 1:length(sol.routePrime)
	# 			if sol.route[i-1] == sol.routePrime[l][1]
	# 				droneFlying = true
	# 				droneFlight = sol.routePrime[l]
	# 				println("DRONE LAUNCH")
	# 				t = t + inst.s_l
	# 				println("t=",t, " tprime=", tprime)
	# 				break
	# 			end
	# 		end
	# 	end
	# 	if !droneFlying
	# 		tprime = tprime + inst.tau[sol.route[i-1]+1,sol.route[i]+1]
	# 	end

	# 	if sol.route[i] == droneFlight[3] && droneFlying
	# 		tlaunch = tprime
	# 		tprime = tprime + inst.s_l
	# 		println("BEFORE DRONE TRIP: tprime=",tprime," timePrime[",sol.route[i],"]=", sol.timePrime[sol.route[i]+1])
	# 		tprime = tprime + inst.tauprime[droneFlight[1]+1,droneFlight[2]+1]
	# 		println("+",inst.tauprime[droneFlight[1]+1,droneFlight[2]+1])
	# 		tprime = tprime + inst.tauprime[droneFlight[2]+1,droneFlight[3]+1]
	# 		println("+",inst.tauprime[droneFlight[2]+1,droneFlight[3]+1])
	# 		println("=")
	# 		println("AFTER DRONE TRIP: tprime=",tprime," timePrime[",sol.route[i],"]=", sol.timePrime[sol.route[i]+1])
			
	# 		println("BEFORE SYNCHRONIZATION t=",t, " tprime=", tprime)

	# 		t = max(t, tprime)
	# 		tprime = t
	# 		t = t + inst.s_r
	# 		tprime = tprime + inst.s_r

	# 		println("AFTER SYNCHRONIZATION AND RENDEZVOUS t=",t, " tprime=", tprime)

	# 		if abs(tprime - (tlaunch+inst.s_l)) > inst.endurance
	# 			println("[ERROR] timeFlight = ",tprime-tlaunch, " endurance = ", inst.endurance)
	# 			println("Time of flight exceeded endurance")
	# 			validated = false
	# 		end

	# 		droneAttended = droneAttended + 1
	# 		droneFlying = false
	# 	end

			
	# 	if abs(t - sol.time[sol.route[i]+1]) > 0.00001
	# 		println("[ERROR] t=",t," time[",sol.route[i],"]=", sol.time[sol.route[i]+1])
	# 		println("Time arrival calculated is different from received")
	# 		validated = false
	# 	end
	# 	if sol.route[i] == droneFlight[3] && abs(tprime - sol.timePrime[sol.route[i]+1]) > 0.00001
	# 		println("[ERROR] tprime=",tprime," timePrime[",sol.route[i],"]=", sol.timePrime[sol.route[i]+1])
	# 		println("Time drone arrival calculated is different from received")
	# 		validated = false
	# 	end

	# 	println()
	# end

	# (LAUNCH from current node)
	if !droneFlying
		for l in 1:length(sol.routePrime)
			if sol.route[1] == sol.routePrime[l][1]
				droneFlying = true
				droneFlight = sol.routePrime[l]
				println("DRONE LAUNCH")
				println("t=",t, " tprime=", tprime)
				break
			end
		end
	end

	tlaunch = 0
	for i in 2:length(sol.route)
		println("Estou em ", sol.route[i-1], " e indo para ", sol.route[i])
		println("DIST -> ", inst.tau[sol.route[i-1]+1,sol.route[i]+1])
		t = t + inst.tau[sol.route[i-1]+1,sol.route[i]+1]
		if !droneFlying
			tprime = tprime + inst.tau[sol.route[i-1]+1,sol.route[i]+1]
		end

		if sol.route[i] == droneFlight[3] && droneFlying
			tlaunch = tprime
			println("BEFORE DRONE TRIP: tprime=",tprime," timePrime[",sol.route[i],"]=", sol.timePrime[sol.route[i]+1])
			tprime = tprime + inst.tauprime[droneFlight[1]+1,droneFlight[2]+1]
			println("+",inst.tauprime[droneFlight[1]+1,droneFlight[2]+1])
			tprime = tprime + inst.tauprime[droneFlight[2]+1,droneFlight[3]+1]
			println("+",inst.tauprime[droneFlight[2]+1,droneFlight[3]+1])
			println("=")
			println("AFTER DRONE TRIP: tprime=",tprime," timePrime[",sol.route[i],"]=", sol.timePrime[sol.route[i]+1])
			
			println("BEFORE SYNCHRONIZATION t=",t, " tprime=", tprime)

			t = max(t, tprime)
			tprime = t
			t = t + inst.s_r
			tprime = tprime + inst.s_r

			println("AFTER SYNCHRONIZATION AND RENDEZVOUS t=",t, " tprime=", tprime)

			if abs(tprime - tlaunch) > inst.endurance
				println("[ERROR] timeFlight = ",tprime-tlaunch, " endurance = ", inst.endurance)
				println("Time of flight exceeded endurance")
				validated = false
			end

			droneAttended = droneAttended + 1
			droneFlying = false
		end

		if !droneFlying
			for l in 1:length(sol.routePrime)
				if sol.route[i] == sol.routePrime[l][1]
					droneFlying = true
					droneFlight = sol.routePrime[l]
					println("DRONE LAUNCH")
					t = t + inst.s_l
					tprime = tprime + inst.s_l
					println("t=",t, " tprime=", tprime)
					break
				end
			end
		end
			
		if abs(t - sol.time[sol.route[i]+1]) > 0.00001
			println("[ERROR] t=",t," time[",sol.route[i],"]=", sol.time[sol.route[i]+1])
			println("Time arrival calculated is different from received")
			validated = false
		end
		if sol.route[i] == droneFlight[3] && abs(tprime - sol.timePrime[sol.route[i]+1]) > 0.00001
			println("[ERROR] tprime=",tprime," timePrime[",sol.route[i],"]=", sol.timePrime[sol.route[i]+1])
			println("Time drone arrival calculated is different from received")
			validated = false
		end

		println()
	end

	if droneAttended != length(sol.routePrime)
		println("[ERROR] Customers attended by the drone: ", droneAttended, " != ", length(sol.routePrime))
		validated = false
	end

	return validated

end # function validateSolution()

function freitasFormulation(inst::InstanceData, params::ParameterData)

	println("Running Formulations.freitasFormulation")

	if params.solver == "Gurobi"
		model = Model(Gurobi.Optimizer)
		set_optimizer_attribute(model, "TimeLimit", params.maxtime)
		# if params.disablesolver == 1 #Disable gurobi cuts and presolve
		# 	if params.maxnodes < 999.0
		# 		model = Model(with_optimizer(Gurobi.Optimizer,TimeLimit=params.maxtime,MIPGap=params.tolgap,CliqueCuts=0, CoverCuts=0, FlowCoverCuts=0,FlowPathCuts=0,MIRCuts=0,NetworkCuts=0,GomoryPasses=0, PreCrush=1,NodeLimit=params.maxnodes))
		# 	else
		# 		model = Model(with_optimizer(Gurobi.Optimizer,TimeLimit=params.maxtime,MIPGap=params.tolgap,CliqueCuts=0, CoverCuts=0, FlowCoverCuts=0,FlowPathCuts=0,MIRCuts=0,NetworkCuts=0,GomoryPasses=0, PreCrush=1))
		# 	end
		# else
		# 	if params.maxnodes < 999.0
  		#		model = Model(with_optimizer(Gurobi.Optimizer,TimeLimit=params.maxtime,MIPGap=params.tolgap,PreCrush=1,NodeLimit=params.maxnodes))
		# 	else
		# 		model = Model(with_optimizer(Gurobi.Optimizer,TimeLimit=params.maxtime,MIPGap=params.tolgap,PreCrush=1))
		# 	end
		# end
	#elseif params.solver == "Cplex"
	#	model = Model(solver = CplexSolver(CPX_PARAM_TILIM=params.maxtime,CPX_PARAM_EPGAP=params.tolgap))
	else
		println("No solver selected")
		return 0
	end

	### Defining variables ###

	M = 1000
	@variable(model, t[inst.L] >= 0)
	@variable(model, x[i=inst.V, j=inst.V, l=inst.L], binary = true)
	@variable(model, y[i=inst.V, k=inst.C, j=inst.V, l=inst.L, l_=inst.L], binary = true)

	# ### Objective function ###

	# c1
	@objective(model, Min, sum(t[i]*0.00001 for i in inst.L[1:length(inst.L)-2])+ 100000*t[length(inst.L)-1])

	# # ### Setup constraints ###

	# c2
	sum1 = sum(x[1,j,0] for j in inst.V)
	sum2 = sum(x[j,1,l] for j in inst.V for l in inst.L[2:length(inst.L)])
	@constraint(model, sum1 == sum2, base_name = "c2")
	@constraint(model, sum1 == 1, base_name = "c2")
	@constraint(model, sum2 == 1, base_name = "c2")

	# c3
	for i in inst.V

		sum1 = sum(x[i,j,l] for j in inst.V for l in inst.L)
		sum2 = sum(x[j,i,l] for j in inst.V for l in inst.L)

		@constraint(model,  sum1 == sum2, base_name = "c3")
		@constraint(model,  sum1 <= 1, base_name = "c3")
		@constraint(model,  sum2 <= 1, base_name = "c3")
	end

	# c4
	for k in inst.C # represents V'
		for l in inst.L[2:length(inst.L)]
			@constraint(model, sum(x[j,k,l-1] for j in inst.V) == sum(x[k,j,l] for j in inst.V), base_name = "c4")
		end
	end

	# c5
	for l in inst.L
		@constraint(model, sum(x[i,j,l] for (i,j) in inst.A) <= 1, base_name = "c5")
	end

	# c6
	for l in inst.L
		sum1 = AffExpr(0)
		for (i,k,j) in inst.D
			for l1 in 0:l
				for l2 in (l+1):length(inst.C)+1
					add_to_expression!(sum1, y[i,k,j,l1,l2])
				end
			end
		end
		if sum1 != 0
			@constraint(model, sum1 <= 1, base_name = "c6")
		end
	end

	# c7
	for k in inst.C # represents V'
		sum1 = sum(x[k,j,l] for j in inst.V for l in inst.L)
		sum2 = sum(y[i,k,j,l,l_] for i in inst.V for j in inst.V for l in inst.L for l_ in inst.L)

		@constraint(model, sum1 + sum2 == 1, base_name = "c7")
	end

	# c8
	for i in inst.V
		for l in inst.L
			sum1 = sum(y[i,k,j,l,l_] for k in inst.C for j in inst.V for l_ in inst.L)
			sum2 = sum(x[i,j,l] for j in inst.V)
			@constraint(model, sum1 <= sum2, base_name = "c8")
		end
	end

	# c9
	for j in inst.V
		for l_ in inst.L[2:length(inst.L)] # this is different because l_-1 does not exist when l_ = 0
			sum1 = sum(y[i,k,j,l,l_] for i in inst.V for k in inst.C for l in inst.L)
			sum2 = sum(x[i,j,l_-1] for i in inst.V)
			@constraint(model, sum1 <= sum2, base_name = "c9")
		end
	end

	# c10
	for l in inst.L
		for l_ in inst.L[2:length(inst.L)]
			if l_ > l
				sumY = sum(y[i,k,j,l,l_] for (i,k,j) in inst.D)
				sum1 = AffExpr(0)
				for (i,k,j) in inst.D 
					for l2 in l_+1:length(inst.L)-1
						add_to_expression!(sum1, y[i,k,j,l_,l2])
					end
				end
				@constraint(model, (t[l_] - inst.s_l*sum1) - t[l] <= inst.endurance + M*(1-sumY), base_name = "c10")
			end
		end
	end

	# c11
	for l in inst.L[2:length(inst.L)]
		sum1 = sum(inst.tau[i,j]*x[i,j,l-1] for (i,j) in inst.A)
		
		sum2 = AffExpr(0)

		# # (LAUNCH from previous node)
		# # (LAUNCH from depot is added)
		# for (i,k,j) in inst.D 
		# 	for l_ in l:length(inst.L)-1
		# 		add_to_expression!(sum2, inst.s_l, y[i,k,j,l-1,l_])
		# 	end
		# end

		# (LAUNCH from current node)
		for (i,k,j) in inst.D 
			for l_ in (l+1):(length(inst.L)-1)
				add_to_expression!(sum2, inst.s_l, y[i,k,j,l,l_])
			end
		end
	
		sum3 = AffExpr(0)	
		for (i,k,j) in inst.D
			for l1 in 0:(l-1)
				add_to_expression!(sum3, inst.s_r, y[i,k,j,l1,l])
			end
		end
		@constraint(model, t[l] >= t[l-1] + sum1 + sum2 + sum3)
	end

	# c12
	for l_ in inst.L[2:length(inst.L)]
		for l in inst.L
			if l < l_
				# # (LAUNCH from previous node)
				# # (LAUNCH from depot is added)
				# sum1 = sum((inst.s_l + inst.tauprime[i,k] + inst.tauprime[k,j] + inst.s_r)*y[i,k,j,l,l_] for (i,k,j) in inst.D)
				# @constraint(model, t[l_] >= t[l] + sum1)
				
				# (LAUNCH from current node)
				sum1 = sum((inst.tauprime[i,k] + inst.tauprime[k,j] + inst.s_r)*y[i,k,j,l,l_] for (i,k,j) in inst.D)
				sum2 = AffExpr(0)
				for (i,k,j) in inst.D
					for l1 in (l_+1):(length(inst.L)-1)
						add_to_expression!(sum2, inst.s_l, y[i,k,j,l_,l1])
					end
				end
				@constraint(model, t[l_] >= t[l] + sum1 + sum2)
			end
		end
	end

	# c13
	fix(t[0], 0; force = true)

	# simplification
	for i in inst.V
		for j in inst.V
			if !((i,j) in inst.A)
				for l in inst.L
					fix(x[i,j,l], 0; force = true)
				end
			end
		end
	end

	for i in inst.V
		for k in inst.C
			for j in inst.V
				for l in inst.L
					for l_ in inst.L
						if l >= l_ || !((i,k,j) in inst.D)
							fix(y[i,k,j,l,l_], 0; force = true)
						end
					end
				end
			end
		end
	end

	# write_to_file(model,"modeloFreitas.lp")

	t1 = time_ns()
	status = optimize!(model)
	t2 = time_ns()
	elapsedtime = (t2-t1)/1.0e9

	bestsol = value.(t[length(inst.L)-1])
	bestbound = objective_bound(model)
	# numnodes = node_count(model)
	time = solve_time(model)
	# gap = 100*(bestsol-bestbound)/bestsol

        #println(status)
	opt = 0
	if status == :Optimal
		opt = 1
        end

	open("saida.txt","a") do f
		write(f,";bestsol=$(bestsol);time=$(time)\n")
		# write(f,";$(x);$(value.(x));$(y);$(value.(y));$(p);$(value.(p));$(value.(u));\n")
	end

	sol = createSolutionFreitas(inst, value.(x), value.(y), value.(t))
	printMurrayFormulationSolution(inst, sol)
	# sol = createSolutionMurray(inst,value.(x),value.(y),value.(u),value.(t),value.(tprime),value.(p))

	if validateSolution(inst, sol)
		println("Everything is awesome!")
	end
	# printMurrayFormulationSolution(inst,sol)
end # freitasFormulation()

function getNextCustomer(inst, k, x)
	for l in inst.L
		for j in inst.V
			if x[k,j,l] > 0
				return j,l
			end
		end
	end

end # function getNextCustomer

function createSolutionFreitas(inst, x, y, t)

	# # c10
	# for l in inst.L
	# 	for l_ in inst.L[2:length(inst.L)]
	# 		if l_ > l
	# 			sumY = sum(y[i,k,j,l,l_] for (i,k,j) in inst.D)
	# 			sum1 = AffExpr(0)
	# 			tupla = (0,0,0)
	# 			for (i,k,j) in inst.D 
	# 				for l2 in l_+1:length(inst.L)-1
	# 					if y[i,k,j,l_,l2]>0
	# 						tupla = (i,k,j)
	# 					end
	# 					add_to_expression!(sum1, y[i,k,j,l_,l2])
	# 				end
	# 			end
	# 			println(tupla, " ", l, " ", l_)
	# 			println(sumY)
	# 			println(sum1)
	# 			println(t[l])
	# 			println(t[l_])
	# 			println(inst.endurance)
	# 			println()

	# 			# @constraint(model, (t[l_] - inst.s_l*sum1) - t[l] <= inst.endurance + M*(1-sumY), base_name = "c10")
	# 		end
	# 	end
	# end

	# # c11
	# for l in inst.L[2:length(inst.L)]
	# 	sum1 = sum(inst.tau[i,j]*x[i,j,l-1] for (i,j) in inst.A)
		
	# 	sum2 = AffExpr(0)

	# 	# # (LAUNCH from previous node)
	# 	# # (LAUNCH from depot is added)
	# 	# for (i,k,j) in inst.D 
	# 	# 	for l_ in l:length(inst.L)-1
	# 	# 		add_to_expression!(sum2, inst.s_l, y[i,k,j,l-1,l_])
	# 	# 	end
	# 	# end
	# 	tupla = (0,0,0)
	# 	# (LAUNCH from current node)
	# 	for (i,k,j) in inst.D 
	# 		for l_ in (l+1):(length(inst.L)-1)
	# 			add_to_expression!(sum2, inst.s_l, y[i,k,j,l,l_])
	# 		end
	# 	end
	
	# 	sum3 = AffExpr(0)	
	# 	for (i,k,j) in inst.D
	# 		for l1 in 0:(l-1)
	# 			if y[i,k,j,l1,l]>0
	# 				tupla = (i,k,j)
	# 			end
	# 			add_to_expression!(sum3, inst.s_r, y[i,k,j,l1,l])
	# 		end
	# 	end
	# 	println(tupla, " ", l)
	# 	println(sum1)
	# 	println(sum2)
	# 	println(sum3)
	# 	println(t[l-1])
	# 	println(t[l])
	# 	println(inst.endurance)
	# 	# @constraint(model, t[l] >= t[l-1] + sum1 + sum2 + sum3)
	# end

	# # c12
	# for l_ in inst.L[2:length(inst.L)]
	# 	for l in inst.L
	# 		if l < l_
	# 			# # (LAUNCH from previous node)
	# 			# # (LAUNCH from depot is added)
	# 			# sum1 = sum((inst.s_l + inst.tauprime[i,k] + inst.tauprime[k,j] + inst.s_r)*y[i,k,j,l,l_] for (i,k,j) in inst.D)
	# 			# @constraint(model, t[l_] >= t[l] + sum1)
				
	# 			# (LAUNCH from current node)
	# 			tupla = (0,0,0)
	# 			sum1 = sum((inst.tauprime[i,k] + inst.tauprime[k,j] + inst.s_r)*y[i,k,j,l,l_] for (i,k,j) in inst.D)
	# 			sum2 = AffExpr(0)
	# 			for (i,k,j) in inst.D
	# 				for l1 in (l_+1):(length(inst.L)-1)
	# 					if y[i,k,j,l_,l1] > 0
	# 						tupla = (i,k,j)
	# 					end
	# 					add_to_expression!(sum2, inst.s_l, y[i,k,j,l_,l1])
	# 				end
	# 			end

	# 			println(tupla, " ", l, " ", l_)
	# 			println(sum1)
	# 			println(sum2)
	# 			println(t[l])
	# 			println(t[l_])
	# 			# @constraint(model, t[l_] >= t[l] + sum1 + sum2)
	# 		end
	# 	end
	# end
	# print(t)

	route = Any[]
	time = zeros(Float64, length(inst.L))

	k = 1
	push!(route, k-1)
	next_k,l = getNextCustomer(inst, k, x)
	time[k] = t[l]
	k = next_k
	push!(route, k-1)
	while k-1 != 0
		next_k,l = getNextCustomer(inst, k, x)
		time[k] = t[l]
		k = next_k
		if k-1 == 0
			push!(route, length(inst.C)+1)
			time[length(inst.C)+2] = t[length(inst.C)+1]
		else
			push!(route, k-1)
		end
	end

	# println(time)
	# println(t)

	# println(route)
	routePrime = Any[]
	timePrime = zeros(Float64, length(inst.L))
	for i in inst.V
		for k in inst.C
			for j in inst.V 
				for l in inst.L  
					for l_ in inst.L
						if y[i,k,j,l,l_] > 0 
							timePrime[i] = t[l]
							timePrime[j] = t[l_]
							if j-1 == 0
								push!(routePrime, (i-1,k-1,11))
								timePrime[length(inst.C)+2] = t[length(inst.C)+1]
							else
								push!(routePrime, (i-1,k-1,j-1))
							end
						end
					end
				end
			end
		end
	end

	# println(routePrime)


	sol = Solution(route, routePrime, time, timePrime)

	return sol

end # function createSolutionFreitas()


end # module
