using DiffFusion
using Test

@testset "Composite models for joint simulation." begin

    include("simple_model.jl")
    include("diagonal_model.jl")

end
