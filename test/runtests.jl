
using DiffFusion
using Test

using Logging

@info "Start testing DiffFusion package."

@testset verbose=true "DiffFusion.jl" begin

    # specify default test file here
    file_name = "unittests/unittests_fast.jl"
    # allow amending test file via argument
    if @isdefined(ARGS) && length(ARGS) > 0
        file_name = ARGS[1]
        @info "Run tests " * file_name * " from test_args."
    end
    include(file_name)

end

@info "Finished testing DiffFusion package."
