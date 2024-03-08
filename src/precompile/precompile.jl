using PrecompileTools

# A sequence of function calls used to pre-compile and store code.
@compile_workload begin
    include("termstructures.jl")
    include("models.jl")
    include("simulations.jl")
    include("paths.jl")
    include("scenarios.jl")
end
