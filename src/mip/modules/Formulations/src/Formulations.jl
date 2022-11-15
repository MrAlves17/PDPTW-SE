module Formulations

using JuMP
using Gurobi
#using CPLEX
using Data
using Parameters
using Infinity

struct Solution
	route
	routePrime
	time
	timePrime
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

	@variable(model, x[i=inst.Vprime,j=inst.Vprime,k=inst.K; j != i], binary = true)
	@variable(model, z[i=inst.Vprime,k=inst.K] >= 0)

	# Scheduling variables

	@variable(model, t[i=inst.V] >= 0)
	@variable(model, C[k=inst.K] >= 0)
	@variable(model, phi[i=inst.Vprime, j=inst.Vprime, h=inst.H; (i,j) in inst.A_m], binary = true)
	# @variable(model, gamma[i=inst.Vprime, j=inst.Vprime, iprime=inst.Vprime, jprime=inst.Vprime, h=inst.H; (i,j) in inst.A_m && (iprime, jprime) in inst.A_m], binary = true)
	# @variable(model, alpha[i=inst.Vprime, j=inst.Vprime, h=inst.H; (i,j) in inst.A_m] >= 0)

	### Routing Constraints ###

	it = 1
	# c1
	for k in inst.K
		sumX = sum(x[1,j,k] for j in inst.V_p)
		@constraint(model, sumX == 1, base_name = "c1")
	end
	println("banana ", it)
	it+= 1

	# c2
	for k in inst.K
		for i in inst.V[2:length(inst.V)]
			sum1 = sum(x[j,i,k] for (j,p) in inst.A if p == i)
			sum2 = sum(x[i,j,k] for (j,p) in inst.A if p == i)

			@constraint(model, sum1 - sum2 == 0, base_name = "c2")
		end
	end
	println("banana ", it)
	it+= 1

	# c3
	for k in inst.K
		sumX = sum(x[j,2*inst.n+2, k] for j in inst.V_d)

		@constraint(model, sumX == 1, base_name = "c3")
	end
	println("banana ", it)
	it+= 1

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
	println("banana ", it)
	it+= 1

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
	println("banana ", it)
	it+= 1

	# c6
	for k in inst.K
		@constraint(model, z[1,k] == 0, base_name = "c6")
	end
	println("banana ", it)
	it+= 1

	# c7
	for k in inst.K
		for (i,j) in inst.A
			@constraint(model, z[j,k] >= z[i,k] + inst.q[i] - M*(1-x[i,j,k]), base_name = "c7")
		end
	end
	println("banana ", it)
	it+= 1

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
	println("banana ", it)
	it+= 1

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
	println("banana ", it)
	it+= 1


	### Scheduling constraints ###

	# c12
	for k in inst.K
		for (i,j) in inst.A
			if j in inst.V
				println(inst.d[i,j,k])
				println(x[i,j,k])
				@constraint(model, t[j] >= t[i] + inst.s[i] + inst.d[i,j,k] - M*(1-x[i,j,k]), base_name = "c12")
			end
		end
	end
	println("banana ", it)
	it+= 1

	# c13
	for i in inst.V_p
		@constraint(model, t[i] + inst.s[i] <= t[inst.n+i], base_name="c13")
	end
	println("banana ", it)
	it+= 1

	# c14
	for i in inst.V[2:length(inst.V)]
		@constraint(model, inst.tasks[inst.refs[i]].earl <= t[i] <= inst.tasks[inst.refs[i]].lat, base_name = "c14")
	end
	println("banana ", it)
	it+= 1

	# c15
	fix(t[1], 0; force = true)
	println("banana ", it)
	it+= 1

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
	println("banana ", it)
	it+= 1

	# # c17
	# for h in inst.H
	# 	for k in inst.K
	# 		for (i,j) in inst.A_m
	# 			@constraint(model, alpha[i,j,h] >= t[i] + inst.s[i] + inst.d_bar[i,h,k] - M*(1-phi[i,j,h]), base_name = "c17")
	# 		end
	# 	end
	# end
	# println("banana ", it)
	# it+= 1

	# # c18
	# for h in inst.H
	# 	for k in inst.K
	# 		for (i,j) in inst.A_m
	# 			if j in inst.V
	# 				@constraint(model, t[j] >= alpha[i,j,h] + inst.O[i,j,h] + inst.d_bar[j,h,k] - M*(2-phi[i,j,h]-x[i,j,k]), base_name = "c18")
	# 			end
	# 		end
	# 	end
	# end
	# println("banana ", it)
	# it+= 1

	# # c19
	# for h in inst.H
	# 	for (i,j) in inst.A_m
	# 		for (iprime, jprime) in inst.A_m
	# 			@constraint(model, gamma[i,j,iprime,jprime,h] + gamma[iprime,jprime,i,j,h] >= phi[i,j,h] + phi[iprime, jprime, h] - 1, base_name = "c19")
	# 		end
	# 	end
	# end
	# println("banana ", it)
	# it+= 1

	# # c20
	# for h in inst.H
	# 	for (i,j) in inst.A_m
	# 		for (iprime, jprime) in inst.A_m
	# 			@constraint(model, gamma[i,j,iprime,jprime,h] <= phi[i,j,h], base_name = "c20")
	# 		end
	# 	end
	# end
	# println("banana ", it)
	# it+= 1

	# # c21
	# for h in inst.H
	# 	for (i,j) in inst.A_m
	# 		for (iprime, jprime) in inst.A_m
	# 			@constraint(model, gamma[iprime,jprime,i,j,h] <= phi[i,j,h], base_name = "c21")
	# 		end
	# 	end
	# end
	# println("banana ", it)
	# it+= 1

	# # c22
	# for h in inst.H
	# 	for (i,j) in inst.A_m
	# 		for (iprime, jprime) in inst.A_m
	# 			@constraint(model, alpha[iprime,jprime,h] >= alpha[i,j,h] + O[i,j,h] + O[j,iprime,h] - M*(1-gamma[i,j,iprime,jprime,h]), base_name = "c22")
	# 		end
	# 	end
	# end
	# println("banana ", it)
	# it+= 1

	# # c23
	# for k in inst.K
	# 	for (i,p) in inst.A
	# 		if p == 2*inst.n+2
	# 			@constraint(model, C[k] >= t[i] + inst.s[i] + d[i,2*inst.n+2,k] - M*(1-x[i,2*inst.n+2,k]), base_name = "c23")
	# 		end
	# 	end
	# end
	# println("banana ", it)
	# it+= 1

	# # c24
	# for h in inst.H 
	# 	for k in inst.K
	# 		for (i,p) in inst.A
	# 			if p == 2*inst.n+2
	# 				@constraint(model, C[k] >= alpha[i,2*inst.n+2,h] + O[i,2*inst.n+2,h] + inst.d_bar[2*inst.n+2, h, k] - M*(1-x[i,2*inst.n+2,k]), base_name = "c24")
	# 			end
	# 		end
	# 	end
	# end
	# println("banana ", it)
	# it+= 1


	# ### Objective function ###

	# c30
	@objective(model, Min, sum(C))
	println("banana ", it)
	it+= 1

	# write_to_file(model,"modelo.lp")

	t1 = time_ns()
	println("starting")
	status = optimize!(model)
	println("final")
	t2 = time_ns()
	elapsedtime = (t2-t1)/1.0e9

	bestsol = sum(value.(C))
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

	# x_value = value.(x)
	# y_value = value.(y)
	# u_value = value.(u)
	# t_value = value.(t)
	# tprime_value = value.(tprime)
	# p_value = value.(p)

	# sol = createSolutionMurray(inst,value.(x),value.(y),value.(u),value.(t),value.(tprime),value.(p))
	# printMurrayFormulationSolution(inst,sol)

	# if validateSolution(inst, sol)
	# 	println("Everything is awesome!")
	# end

end #function meloFormulation()


end # module
