module Formulations

using JuMP
using Gurobi
#using CPLEX
using Data
using Parameters
using Infinity

struct Solution
	routes
	times
end

export meloFormulation

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

	M = 999999

	# Routing variables

	@variable(model, x[i=inst.Vprime,j=inst.Vprime,k=inst.K; (i,j) in inst.A], binary = true)
	@variable(model, z[i=inst.Vprime,k=inst.K] >= 0)
	
	# Scheduling variables

	@variable(model, t[i=inst.V] >= 0)
	@variable(model, C[k=inst.K] >= 0)
	@variable(model, phi[i=inst.Vprime, j=inst.Vprime, h=inst.H; (i,j) in inst.A_m], binary = true)
	@variable(model, gamma[i=inst.Vprime, j=inst.Vprime, iprime=inst.Vprime, jprime=inst.Vprime, h=inst.H; (i,j) in inst.A_m && (iprime, jprime) in inst.A_m], binary = true)
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
					@constraint(model, t[j] >= alpha[i,j,h] + inst.O[i][j][h] + inst.d_bar[j][h][k] - M*(2-phi[i,j,h]-x[i,j,k]), base_name = "c18")
				end
			end
		end
	end

	# # c19
	# for h in inst.H
	# 	for (i,j) in inst.A_m
	# 		for (iprime, jprime) in inst.A_m
	# 			@constraint(model, gamma[i,j,iprime,jprime,h] + gamma[iprime,jprime,i,j,h] >= phi[i,j,h] + phi[iprime, jprime, h] - 1, base_name = "c19")
	# 		end
	# 	end
	# end

	# # c20
	# for h in inst.H
	# 	for (i,j) in inst.A_m
	# 		for (iprime, jprime) in inst.A_m
	# 			@constraint(model, gamma[i,j,iprime,jprime,h] <= phi[i,j,h], base_name = "c20")
	# 		end
	# 	end
	# end

	# # c21
	# for h in inst.H
	# 	for (i,j) in inst.A_m
	# 		for (iprime, jprime) in inst.A_m
	# 			@constraint(model, gamma[iprime,jprime,i,j,h] <= phi[i,j,h], base_name = "c21")
	# 		end
	# 	end
	# end

	# # c22
	# for h in inst.H
	# 	for (i,j) in inst.A_m
	# 		for (iprime, jprime) in inst.A_m
	# 			@constraint(model, alpha[iprime,jprime,h] >= alpha[i,j,h] + inst.O[i][j][h] + inst.O[j][iprime][h] - M*(1-gamma[i,j,iprime,jprime,h]), base_name = "c22")
	# 		end
	# 	end
	# end

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
					@constraint(model, C[k] >= alpha[i,2*inst.n+2,h] + inst.O[i][2*inst.n+2][h] + inst.d_bar[2*inst.n+2][h][k] - M*(1-x[i,2*inst.n+2,k]), base_name = "c24")
				end
			end
		end
	end


	# ### Objective function ###

	# c30
	@objective(model, Min, sum(C))

	write_to_file(model,"modelo.lp")

	t1 = time_ns()
	println("starting")
	status = optimize!(model)
	println("final")
	t2 = time_ns()
	elapsedtime = (t2-t1)/1.0e9

	println(status)
	bestsol = sum(value.(C))
	bestbound = objective_bound(model)
	# numnodes = node_count(model)
	time = solve_time(model)
	gap = 100*(bestsol-bestbound)/bestsol

	opt = 0
	if status == :Optimal
		opt = 1
        end

	open("saida.txt","a") do f
		write(f,";bestsol=$(bestsol);time=$(time)\n")
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
	printMeloFormulationSolution(inst,sol)

	if validateSolution(inst, sol)
		println("Everything is awesome!")
	end

end #function meloFormulation()

function createSolutionMelo(inst::InstanceData, x, z, t, C, phi, gamma, alpha)
	M = 999999

	# c1
	# for k in inst.K
	# 	sumX = 0
	# 	get_j = 0
	# 	for j in inst.V_p
	# 		sumX += x[1,j,k]
	# 		if x[1,j,k] == 1
	# 			get_j = j
	# 		end
	# 	end
	# 	sumX += x[1,2*inst.n+2,k]
	# 	if x[1,2*inst.n+2,k] == 1
	# 		get_j = 2*inst.n+2
	# 	end
	# 	# println(k)
	# 	println(sumX == 1)
	# 	println(1,' ',get_j,' ',k)
	# 	println(x[1,get_j,k])
	# 	# @constraint(model, sumX == 1, base_name = "c1")
	# end
	# println()
	# # c2
	# for k in inst.K
	# 	for i in inst.V[2:length(inst.V)]
	# 		sum1 = 0
	# 		get_j = 0
	# 		for (j,p) in inst.A
	# 			if p == i
	# 				sum1 += x[j,i,k]
	# 				if x[j,i,k] == 1
	# 					get_j = j
	# 				end
	# 			end
	# 		end

	# 		if sum1 > 0
	# 			println(get_j, i, k)
	# 			println(x[get_j,i,k])
	# 		end
	# 		println(sum1)
	# 		sum2 = 0
	# 		get_j = 0
	# 		for (p,j) in inst.A
	# 			if p == i
	# 				sum2 += x[i,j,k]
	# 				if x[i,j,k] == 1
	# 					get_j = j
	# 				end
	# 			end
	# 		end

	# 		if sum2 > 0
	# 			println(i, get_j, k)
	# 			println(x[i,get_j,k])
	# 		end
	# 		println(sum2)
	# 		println(sum1 - sum2 == 0)

	# 		# @constraint(model, sum1 - sum2 == 0, base_name = "c2")
	# 	end
	# end
	# println()

	# # c3
	# for k in inst.K
	# 	sumX = 0
	# 	get_j = 0
	# 	for j in inst.V_d
	# 		sumX += x[j,2*inst.n+2,k]
	# 		if x[j,2*inst.n+2,k] == 1
	# 			get_j = j
	# 		end
	# 	end
	# 	sumX += x[1,2*inst.n+2, k]
	# 	if x[1,2*inst.n+2,k] == 1
	# 		get_j = 1
	# 	end
	# 	println(get_j, 2*inst.n+2, k)
	# 	println(x[get_j, 2*inst.n+2, k])
	# 	println(sumX)
	# 	println(sumX == 1)
	# 	# @constraint(model, sumX == 1, base_name = "c3")
	# end

	# println()
	# # c4
	# for i in inst.V[2:length(inst.V)]
	# 	sumX = 0
	# 	get_j = 0
	# 	get_k = 0
	# 	for k in inst.K
	# 		for (j,p) in inst.A
	# 			if p == i
	# 				sumX += x[j,i,k]
	# 				if x[j,i,k] == 1
	# 					get_j = j
	# 					get_k = k
	# 				end
	# 			end
	# 		end
	# 	end
	# 	println(get_j, i, get_k)
	# 	println(x[get_j,i,get_k])
	# 	println(sumX)
	# 	println(sumX == 1)
	# 	# @constraint(model, sumX == 1, base_name="c4")
	# end

	# println()
	# # c5
	# for k in inst.K
	# 	for i in inst.V_p
	# 		sum1 = 0
	# 		get_j = 0
	# 		for (j,p) in inst.A
	# 			if p == i
	# 				sum1 += x[j,i,k]
	# 				if x[j,i,k] == 1
	# 					get_j = j
	# 				end
	# 			end
	# 		end

	# 		if sum1 > 0
	# 			println(get_j, i, k)
	# 			println(x[get_j,i,k])
	# 		end
	# 		println(sum1)

	# 		sum2 = 0
	# 		get_j = 0
	# 		for (j,p) in inst.A
	# 			if p == inst.n+i
	# 				sum2 += x[j,inst.n+i,k]
	# 				if x[j,inst.n+i,k] == 1
	# 					get_j = j
	# 				end
	# 			end
	# 		end

	# 		if sum2 > 0
	# 			println(get_j, i+inst.n, k)
	# 			println(x[get_j,inst.n+i,k])
	# 		end
	# 		println(sum2)

	# 		println(sum1 == sum2)

	# 		# @constraint(model, sum1 == sum2, base_name="c5")
	# 	end
	# end
	# println()

	routes = Any[]
	times = Any[]
	# println(x)

	for k in inst.K
		push!(routes, Any[])
		push!(times, Any[])
		i=1
		while i != length(inst.Vprime)
			push!(routes[k], inst.tasks[inst.refs[i]].id)
			push!(times[k], t[i])
			for j in inst.Vprime
				if (i,j) in inst.A && x[i,j,k] > 0
					i = j
					break
				end
			end
		end
		push!(routes[k], inst.tasks[inst.refs[i]].id)
		push!(times[k], C[k])
	end

	sol = Solution(routes, times)

	return sol

end # function createSolutionMelo()

function printMeloFormulationSolution(inst::InstanceData, sol::Solution)
	for k in inst.K
		print(k,' ')
		for i in 1:length(sol.routes[k])
			print(sol.routes[k][i], '(', sol.times[k][i], ')', " --> ")
		end
		println()
	end

end # function printMeloFormulationSolution

function validateSolution(inst::InstanceData, sol::Solution)
	
	
	return true
end # module
