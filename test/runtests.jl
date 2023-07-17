using Revise

using DiffFusion
using Test

using Logging

@info "Start testing DiffFusion package."

@testset verbose=true "DiffFusion.jl" begin

    include("unittests/unittests.jl")

end

@info "Finished testing DiffFusion package."
