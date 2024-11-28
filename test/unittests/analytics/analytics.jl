using DiffFusion
using PerformanceTestTools
using Test

@testset "Methods for exposure simulation and collateral simulation." begin

    include("scenarios.jl")
    include("scenario_analytics.jl")
    include("collateral.jl")
    include("covariances.jl")
	
    PerformanceTestTools.@include_foreach(
        "scenarios_parallel.jl",
        [
            nothing,
            [`--project=.`, `-t 2`],
            [`--project=.`, `-p 5`],
            [`--project=.`, `-p 3`, `-t 2`],
        ],
    )

end
