using DiffFusion
using Test

@testset "Commonly used utility methods." begin

    include("bachelier.jl")
    include("barriers.jl")
    include("black.jl")
    include("polynomialregression.jl")
    include("piecewiseregression.jl")

end
