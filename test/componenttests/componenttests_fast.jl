using DiffFusion
using Test

@info "Start componenttests_fast.jl."

@testset verbose=true "componenttests_fast.jl" begin

    include("calibration/swap_rate_calibration.jl")

    include("scenarios/asset_options.jl")
    include("scenarios/bermudan_swaption.jl")
    include("scenarios/rates_option.jl")
    include("scenarios/scenarios.jl")
    include("scenarios/swaptions_expected_exposure.jl")

end

@info "Finishes componenttests_fast.jl."
