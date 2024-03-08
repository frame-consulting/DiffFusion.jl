using DiffFusion
using Test

@testset "Methods for exposure simulation and collateral simulation." begin

    include("scenarios.jl")
    include("scenario_analytics.jl")
    include("collateral.jl")
	
end
