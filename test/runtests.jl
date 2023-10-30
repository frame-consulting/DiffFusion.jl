
using DiffFusion
using Test

using Logging

@info "Start testing DiffFusion package."

@testset verbose=true "DiffFusion.jl" begin

    if @isdefined(ARGS) && length(ARGS) > 0
        @info "Run tests " * ARGS[1] * " from test_args."
        @testset verbose=true "Runtests" begin
            include(ARGS[1])
        end
    else
        @testset verbose=true "Unit tests" begin
            include("unittests/unittests.jl")
        end
    end

end

@info "Finished testing DiffFusion package."
