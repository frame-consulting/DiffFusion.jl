
using Test

@info "Start unittests_slow.jl."

@testset verbose=true "unittests_slow.jl" begin

    include("analytics/valuations.jl")

end

@info "Finished unittests_slow.jl."
