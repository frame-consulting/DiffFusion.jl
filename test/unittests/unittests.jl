
using Test

@info "Start unittests.jl."

@testset verbose=true "unittests.jl" begin

    include("analytics/analytics.jl")
    include("examples/examples.jl")
    include("models/models.jl")
    include("paths/paths.jl")
    include("payoffs/payoffs.jl")
    include("products/products.jl")
    include("serialisation/serialisation.jl")
    include("simulations/simulations.jl")
    include("termstructures/termstructures.jl")
    include("utils/utils.jl")

end

@info "Finished unittests.jl."
