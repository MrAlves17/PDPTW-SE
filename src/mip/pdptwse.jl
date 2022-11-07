push!(LOAD_PATH, "modules/")
# push!(DEPOT_PATH, JULIA_DEPOT_PATH)
using Pkg
#Pkg.activate(".")
# Pkg.instantiate()
# Pkg.build()

# using JuMP
# using Gurobi

import Data
import Parameters
import Formulations

# Read the parameters from command line
params = Parameters.readInputParameters(ARGS)

# Read instance data
inst = Data.readData(params.instName)

# if params.form == "melo"
# 	Formulations.meloFormulation(inst, params)
# end