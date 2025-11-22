using DiffFusion
using Test

@info "Start componenttests_slow.jl."

@testset verbose=true "componenttests_slow.jl" begin

    include("sensitivities/gradients.jl")
    include("sensitivities/swaptions_delta_vega.jl")

    if DiffFusion._use_zygote
        # Zygote segfaults with v1.12
        include("sensitivities/forwards_deltas_zygote.jl")
        include("sensitivities/option_deltas_zygote.jl")
        include("sensitivities/swap_deltas_zygote.jl")
        include("sensitivities/option_vegas_zygote.jl")
    end

end

@info "Finished componenttests_slow.jl."
