using DiffFusion
using Test

@testset verbose=true "Term structures for simulation and valuation." begin

    # Add tests here.

    include("correlation/correlation.jl")
    include("credit/credit.jl")
    include("futures/futures.jl")
    include("inflation/inflation.jl")
    include("parameter/parameter.jl")
    include("rates/rates.jl")
    include("volatility/volatility.jl")

end
