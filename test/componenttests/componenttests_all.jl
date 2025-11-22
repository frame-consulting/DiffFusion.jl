using DiffFusion
using Test

@info "Start componenttests_all.jl."

@testset verbose=true "componenttests_all.jl" begin

    include("componenttests_fast.jl")
    include("componenttests_slow.jl")

end

@info "Finished componenttests_all.jl."
