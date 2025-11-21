
using Test

@info "Start unittests_slow.jl."

@testset verbose=true "unittests_slow.jl" begin

    include("analytics/valuations.jl")
    if VERSION < v"1.12"
        # Zygote yields segfault with v1.12
        include("analytics/valuations_zygote.jl")
    end

end

@info "Finished unittests_slow.jl."
