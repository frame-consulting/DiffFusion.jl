
using DiffFusion
using Test

@testset "Test delayed calculations" begin
    
    @testset "Test delayed calculations" begin
        @test isnothing(DiffFusion.later(0.1))
        #
        f = (x) -> 2*x
        @test DiffFusion.later(0.1, f, 1.0) == 2.0
        #
        f = DiffFusion.flat_forward
        ts = DiffFusion.later(0.1, DiffFusion.flat_forward, 0.03)
        @test ts == DiffFusion.FlatForward{Float64}("", 0.03)
    end

end
