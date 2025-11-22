
using Test

@info "Start unittests_slow.jl."

@testset verbose=true "unittests_slow.jl" begin

    include("analytics/valuations.jl")
    if DiffFusion._use_zygote
        # Zygote yields segfault with v1.12
        include("analytics/valuations_zygote.jl")
    end

end

@info "Finished unittests_slow.jl."
