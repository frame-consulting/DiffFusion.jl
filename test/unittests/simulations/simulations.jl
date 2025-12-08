using DiffFusion
using Test

@testset "MC simulations, paths and states." begin

    # Add tests here.
    include("asset_model.jl")
    include("cev_asset_model.jl")
    include("gaussain_hjm_model.jl")
    include("markov_future_model.jl")
    include("ornstein_uhlenbeck_model.jl")
    include("cox_ingersoll_ross_model.jl")
    include("simple_models.jl")
    include("diagonal_model.jl")

end
