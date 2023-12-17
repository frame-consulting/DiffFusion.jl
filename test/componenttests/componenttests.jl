using DiffFusion
using Test

@info "Start componenttests.jl."

@testset verbose=true "componenttests.jl" begin

    include("calibration/swap_rate_calibration.jl")

    include("scenarios/scenarios.jl")
    include("scenarios/rates_option.jl")
    include("scenarios/bermudan_swaption.jl")
    include("scenarios/swaptions_expected_exposure.jl")

    include("sensitivities/forwards_deltas.jl")
    include("sensitivities/option_deltas.jl")
    include("sensitivities/swap_deltas.jl")
    include("sensitivities/option_vegas.jl")
    include("sensitivities/swaptions_delta_vega.jl")

    include("sensitivities/gradients.jl")

end

@info "Start componenttests.jl."
