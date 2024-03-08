
using Test

@info "Start unittests_all.jl."

@testset verbose=true "unittests_all.jl" begin

    include("unittests_fast.jl")
    include("unittests_slow.jl")

end

@info "Finished unittests_all.jl."
