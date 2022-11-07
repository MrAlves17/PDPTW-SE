module Parameters

struct ParameterData
	instName::String
	form::String
	balanced::Int
	solver::String
	maxtime::Int
	tolgap::Float64
	printsol::Int
	capacity::Float64
	capacityw::Float64
	capacityr::Float64
	disablesolver::Int
	dpseed::Int
	dpalpha::Float64
	dptype::Int
	dpmaxiter::Int
	dpmaxtime::Int
	tolsep::Float64
	cpmaxrounds::Int
	maxnodes::Int
end

export ParameterData, readInputParameters

function readInputParameters(ARGS)
	#println("Running Parameters.readInputParameters")

	### Set standard values for the parameters ###
	instName="instances/N50T15/N50T15P1W5DD_SF1.dat"
	form="esn"
	balanced = 0
	solver = "Gurobi"
	maxtime = 3600
	tolgap = 0.000001
	printsol = 0
	capacity = 1.5
	capacityw = 0.0
	capacityr = 0.0
	disablesolver = 0
	dpseed = 1234
	dpalpha = 0.20
	dptype = 1
	dpmaxiter = 500
	dpmaxtime = 2
	tolsep = 10.0
	cpmaxrounds = 1000
	maxnodes = 10000.0

	### Read the parameters and set correct values whenever provided ###
	for param in 1:length(ARGS)
		if ARGS[param] == "--inst"
			instName = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--solver"
			solver = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--maxtime"
			maxtime = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--tolgap"
			tolgap = parse(Float64,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--capacity"
			capacity = parse(Float64,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--capacityw"
			capacityw = parse(Float64,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--capacityr"
			capacityr = parse(Float64,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--printsol"
			printsol = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--balanced"
			balanced = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--disablesolver"
			disablesolver = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--form"
			form = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--dpseed"
			dpseed = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--dpalpha"
			dpalpha = parse(Float64,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--dptype"
			dptype = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--dpmaxiter"
			dpmaxiter = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--dpmaxtime"
			dpmaxtime = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--tolsep"
			tolsep = parse(Float64,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--cpmaxrounds"
			cpmaxrounds = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--maxnodes"
			maxnodes = parse(Float64,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--dpredperiods"
			dpredperiods = parse(Float64,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--dpcostreductionret"
			dpcostreductionret = parse(Float64,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--dpcostreductionware"
			dpcostreductionware = parse(Float64,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--fixsizefo"
			fixsizefo = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--horsizefo"
			horsizefo = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--freeintervalfo"
			freeintervalfo = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--minroundsfo"
			minroundsfo = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--maxtimefo"
			maxtimefo = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--tolgapfo"
			tolgapfo = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--fixsizerf"
			fixsizerf = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--freeintervalrf"
			freeintervalrf = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--maxtimerf"
			maxtimerf = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--tolgaprf"
			tolgaprf = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--fixonlyonesrf"
			fixonlyonesrf = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--inchorfo"
			inchorfo = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--incfixfo"
			incfixfo = parse(Int,ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--tolimprov"
			tolimprov = parse(Float64,ARGS[param+1])
			param += 1
		end
	end

	params = ParameterData(instName, form, balanced, solver, maxtime, tolgap, printsol, capacity, capacityw, capacityr, disablesolver, dpseed, dpalpha, dptype, dpmaxiter, dpmaxtime, tolsep, cpmaxrounds, maxnodes)

	return params

end ### end readInputParameters

end ### end module
