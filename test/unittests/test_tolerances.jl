
"""
Monte Carlo random numbers appear to be system-specific.

We want to allow for different test tolerances when running tests
locally compared to when running tests in CI pipelines.
"""

if isfile(joinpath(@__DIR__, "test_tolerances.local.jl"))
    # Use set tolerances for local run in test_tolerances.local.jl
    include("test_tolerances.local.jl")
else
    test_tolerances = Dict(
        "simulations/asset_model.jl"        => if (VERSION < v"1.7") 0.06 else 0.08 end,
        "simulations/gaussian_hjm_model.jl" => if (VERSION < v"1.7") 0.05 else 0.05 end,
    )
end
