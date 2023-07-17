using DiffFusion
using Test

@testset verbose=true "Component and composite models." begin

    # Add tests here.

    include("asset/asset.jl")
    include("credit/credit.jl")
    include("futures/futures.jl")
    include("hybrid/hybrid.jl")
    include("inflation/inflation.jl")
    include("rates/rates.jl")

end
