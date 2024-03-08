using DiffFusion
using Test

@info "Start componenttests_slow.jl."

@testset verbose=true "componenttests_slow.jl" begin

    include("sensitivities/forwards_deltas.jl")
    include("sensitivities/option_deltas.jl")
    include("sensitivities/swap_deltas.jl")
    include("sensitivities/option_vegas.jl")
    include("sensitivities/swaptions_delta_vega.jl")

    include("sensitivities/gradients.jl")

end

@info "Start componenttests_slow.jl."
