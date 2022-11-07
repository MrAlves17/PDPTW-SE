push!(LOAD_PATH, "modules/")
# push!(DEPOT_PATH, JULIA_DEPOT_PATH)
using Pkg
#Pkg.activate(".")
# Pkg.instantiate()
# Pkg.build()

using JuMP
using Gurobi
#using CPLEX

import Data
import Parameters
import Formulations
#import Heuristics
# import DPHeuristicsCC
#import LagrangianRelaxation
# import RelaxAndFix

# Read the parameters from command line

type = ["37","40","43"]
for i in 1:3
	for j in 1:12
		nameInstance = "instances/Murray_Chu_2015_test_data/FSTSP/FSTSP_10_customer_problems/20140810T1234"*type[i]*"v"*string(j)*"/"
		args = ["testes.jl","--inst",nameInstance, "--form", ARGS[1], "--maxtime", "30"]
		params = Parameters.readInputParameters(args)

		# Read instance data
		inst = Data.readData(params.instName)

		if params.form == "murray"
			Formulations.murrayFormulation(inst, params)
		elseif params.form == "freitas"
			Formulations.freitasFormulation(inst, params)
		end
	end
end