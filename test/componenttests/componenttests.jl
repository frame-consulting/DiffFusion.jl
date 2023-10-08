using DiffFusion
using Test

@info "Start componenttests.jl."

@testset verbose=true "componenttests.jl" begin

    include("scenarios/scenarios.jl")

    include("sensitivities/forwards_deltas.jl")
    include("sensitivities/option_deltas.jl")
    include("sensitivities/swap_deltas.jl")
    include("sensitivities/option_vegas.jl")


end

@info "Start componenttests.jl."
