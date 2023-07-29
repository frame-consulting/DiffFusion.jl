using DiffFusion
using Test

@testset "MC simulations, paths and states." begin

    # Add tests here.
    include("asset_model.jl")
    include("gaussain_hjm_model.jl")
    include("simple_models.jl")

end
