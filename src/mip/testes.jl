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

type = ["lc","lr","lrc"]
for i in 1:3
	for (root, dirs, files) in walkdir("../../instances/pdptw-se_2_100/")
		for dir in dirs
			nameInstance = "../../instances/pdptw-se_1_10/"*dir*'/'
			args = ["testes.jl","--inst",nameInstance, "--maxtime", "30", "--cutoff", "5"]
			params = Parameters.readInputParameters(args)

			# Read instance data
			inst = Data.readData(params.instName, params)
			Formulations.meloFormulation(inst,params)
		end
	end
end