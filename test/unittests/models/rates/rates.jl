using DiffFusion
using Test

@testset "Interest rate models." begin

    include("separable_hjm_model.jl")
    include("gaussian_hjm_model.jl")
    include("forward_rate_volatility.jl")
    include("swap_rate_volatility.jl")
    include("swap_rate_calibration.jl")

end
