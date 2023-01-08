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
for (root, dirs, files) in walkdir("../../instances/pdptw-se_1_16/")
	for dir in dirs
		nameInstance = "../../instances/pdptw-se_1_16/"*dir*'/'
		args = ["testes.jl","--inst",nameInstance, "--maxtime", "1800", "--cutoff", "8"]
		params = Parameters.readInputParameters(args)

		# Read instance data
		inst = Data.readData(params.instName, params)
		Formulations.meloFormulation(inst,params)
	end
end
