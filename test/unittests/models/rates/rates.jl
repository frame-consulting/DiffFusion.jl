using DiffFusion
using Test

@testset "Interest rate models." begin

    include("separable_hjm_model.jl")
    include("gaussian_hjm_model.jl")

end