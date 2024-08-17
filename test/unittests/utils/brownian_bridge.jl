
using DiffFusion

using Test

@testset "Barrier hit probabilities via Brownian Bridge." begin

    @testset "Hit funtions" begin
        σ = 0.5
        T = 10
        ν² = σ^2 * T
        #
        @test DiffFusion.up_hit_probability(2.0, 1.0, 1.5, ν²) > 0 && DiffFusion.up_hit_probability(2.0, 1.0, 1.5, ν²) < 1
        @test DiffFusion.up_hit_probability(1.8, 1.0, 1.5, ν²) > 0 && DiffFusion.up_hit_probability(1.8, 1.0, 1.5, ν²) < 1
        @test DiffFusion.up_hit_probability(2.0, 1.0, 1.5, ν²) < DiffFusion.up_hit_probability(1.8, 1.0, 1.5, ν²)
        @test DiffFusion.up_hit_probability(2.0, 1.0, 1.5, ν²) == DiffFusion.up_hit_probability(2.0, 1.5, 1.0, ν²)
        @test DiffFusion.up_hit_probability(1.5, 1.0, 1.5, ν²) == 1.0
        @test DiffFusion.up_hit_probability(1.2, 1.0, 1.5, ν²) == 1.0
        @test DiffFusion.up_hit_probability(1.0, 1.0, 1.5, ν²) == 1.0
        @test DiffFusion.up_hit_probability(0.5, 1.0, 1.5, ν²) == 1.0
        @test DiffFusion.up_hit_probability(2.0, 1.0, 1.5, 1.0e-3) == 0.0
        @test DiffFusion.up_hit_probability(1.5, 1.0, 1.5, 1.0e-3) == 1.0
        #
        @test DiffFusion.down_hit_probability(0.5, 1.0, 1.5, ν²) == DiffFusion.down_hit_probability(0.5, 1.5, 1.0, ν²)
        @test DiffFusion.down_hit_probability(0.5, 1.0, 1.5, ν²) == DiffFusion.up_hit_probability(2.0, 1.0, 1.5, ν²)
        @test DiffFusion.down_hit_probability(1.0, 1.0, 1.5, ν²) == 1.0
        @test DiffFusion.down_hit_probability(1.2, 1.0, 1.5, ν²) == 1.0
        @test DiffFusion.down_hit_probability(1.5, 1.0, 1.5, ν²) == 1.0
        @test DiffFusion.down_hit_probability(2.0, 1.0, 1.5, ν²) == 1.0
        @test DiffFusion.down_hit_probability(0.5, 1.0, 1.5, 1.0e-3) == 0.0
        @test DiffFusion.down_hit_probability(1.0, 1.0, 1.5, 1.0e-3) == 1.0
        # broadcasting
        w1 = [ 0.0, 1.0, 2.0, 3.0 ]
        w2 = [ 0.5, 1.5, 2.5, 3.5 ]
        pu = [0.09071795328941251, 0.6703200460356393, 1.0, 1.0]
        pd = [1.0, 1.0, 1.0, 0.30119421191220214]
        @test isapprox(DiffFusion.up_hit_probability(2.0, w1, w2, ν²), pu, atol=1.0e-14)
        @test isapprox(DiffFusion.down_hit_probability(2.0, w1, w2, ν²), pd, atol=1.0e-14)
    end

    @testset "No-hit probabilites" begin
        σ = 0.5
        T = 10
        ν² = σ^2 * T
        #
        h = 2.0 # barrier level
        w = [ 0.0, 1.0, 2.0, 3.0 ]
        pu = DiffFusion.up_hit_probability(h, w, w, ν²)
        pd = DiffFusion.down_hit_probability(h, w, w, ν²)
        #
        W = w * ones(3)'
        V = ν² * ones(4, 2)
        p_no_up = DiffFusion.barrier_no_hit_probability(h, -1, W, V)
        p_no_do = DiffFusion.barrier_no_hit_probability(h, +1, W, V)
        @test p_no_up == (1.0 .- pu) .* (1.0 .- pu)
        @test p_no_do == (1.0 .- pd) .* (1.0 .- pd)
        # broadcasting
        @test DiffFusion.barrier_no_hit_probability(h, -1, W, ν² * ones(1, 2)) == p_no_up
        @test DiffFusion.barrier_no_hit_probability(h, +1, W, ν² * ones(1, 2)) == p_no_do
    end

end