
using DiffFusion

using Test


@testset "Test asset option payoffs" begin
    
    if !@isdefined(TestModels)
        include("../../test_models.jl")
    end

    @testset "Vanilla options" begin
        model = TestModels.hybrid_model_full
        ch = TestModels.ch_full
        times = [0.0]
        n_paths = 3
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        path = DiffFusion.path(sim, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        #
        F = DiffFusion.ForwardAsset(2.0, 5.0, "EUR-USD")
        K = DiffFusion.Fixed(1.25)
        C = DiffFusion.VanillaAssetOption(F, K, +1.0)
        P = DiffFusion.VanillaAssetOption(F, K, -1.0)
        #
        @test DiffFusion.obs_time(C) == 2.0
        @test DiffFusion.obs_time(P) == 2.0
        @test DiffFusion.obs_times(C) == union(Set(0.0), Set(2.0))
        @test string(C) == "Call(S(EUR-USD, 2.00, 5.00), 1.2500)"
        @test string(P) == "Put(S(EUR-USD, 2.00, 5.00), 1.2500)"
        #
        Z = (C - P) - (F - K)
        @test isapprox(Z(path), zeros(3), atol=1.0e-15)
        #
        F = DiffFusion.ForwardAsset(5.0, 5.0, "EUR-USD")
        K = DiffFusion.Fixed(1.25)
        C = DiffFusion.VanillaAssetOption(F, K, +1.0)
        P = DiffFusion.VanillaAssetOption(F, K, -1.0)
        @test C(path) == F(path) .- 1.25
        @test P(path) == zeros(3)
    end
end
