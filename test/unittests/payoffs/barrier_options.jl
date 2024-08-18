
using DiffFusion

using Test

@testset "Test barrier option payoffs" begin

    if !@isdefined(TestModels)
        include("../../test_models.jl")
    end

    @testset "Barrier options setup" begin
        F = DiffFusion.ForwardAsset(2.0, 5.0, "EUR-USD")
        K = DiffFusion.Fixed(1.25)
        H = DiffFusion.Fixed(1.75)
        #
        C = DiffFusion.BarrierAssetOption(F, K, H, "UOC", 0.0, 2)
        P = DiffFusion.BarrierAssetOption(F, K, H, "UIP", 0.0, 2)
        @test DiffFusion.obs_time(C) == 2.0
        @test DiffFusion.obs_time(P) == 2.0
        @test DiffFusion.obs_times(C) == union(Set(0.0), Set(2.0))
        #
        @test string(DiffFusion.BarrierAssetOption(F, K, H, "UOC", 0.0, 2)) == "UOCall(S(EUR-USD, 2.00, 5.00), X = 1.2500, H = 1.7500)"
        @test string(DiffFusion.BarrierAssetOption(F, K, H, "UIC", 0.0, 2)) == "UICall(S(EUR-USD, 2.00, 5.00), X = 1.2500, H = 1.7500)"
        @test string(DiffFusion.BarrierAssetOption(F, K, H, "DOC", 0.0, 2)) == "DOCall(S(EUR-USD, 2.00, 5.00), X = 1.2500, H = 1.7500)"
        @test string(DiffFusion.BarrierAssetOption(F, K, H, "DIC", 0.0, 2)) == "DICall(S(EUR-USD, 2.00, 5.00), X = 1.2500, H = 1.7500)"
        #
        @test string(DiffFusion.BarrierAssetOption(F, K, H, "UOP", 0.0, 2)) == "UOPut(S(EUR-USD, 2.00, 5.00), X = 1.2500, H = 1.7500)"
        @test string(DiffFusion.BarrierAssetOption(F, K, H, "UIP", 0.0, 2)) == "UIPut(S(EUR-USD, 2.00, 5.00), X = 1.2500, H = 1.7500)"
        @test string(DiffFusion.BarrierAssetOption(F, K, H, "DOP", 0.0, 2)) == "DOPut(S(EUR-USD, 2.00, 5.00), X = 1.2500, H = 1.7500)"
        @test string(DiffFusion.BarrierAssetOption(F, K, H, "DIP", 0.0, 2)) == "DIPut(S(EUR-USD, 2.00, 5.00), X = 1.2500, H = 1.7500)"
    end


    @testset "Barrier options valuation" begin
        model = TestModels.hybrid_model_full
        ch = TestModels.ch_full
        times = [0.0, 2.0, 5.0]
        n_paths = 8
        sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        path = DiffFusion.path(sim, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)
        #
        F = DiffFusion.ForwardAsset(2.0, 5.0, "EUR-USD")
        K = DiffFusion.Fixed(1.25)
        C = DiffFusion.VanillaAssetOption(F, K, +1)(path)
        P = DiffFusion.VanillaAssetOption(F, K, -1)(path)
        for barrier_level in [ 1.25, 1.30, 1.35, 1.45 ]
            H = DiffFusion.Fixed(barrier_level)
            UOC = DiffFusion.BarrierAssetOption(F, K, H, "UOC", 0.0, 4)(path)
            UIC = DiffFusion.BarrierAssetOption(F, K, H, "UIC", 0.0, 4)(path)
            UOP = DiffFusion.BarrierAssetOption(F, K, H, "UOP", 0.0, 4)(path)
            UIP = DiffFusion.BarrierAssetOption(F, K, H, "UIP", 0.0, 4)(path)
            @test isapprox(UOC + UIC, C, atol=1.0e-14)
            @test isapprox(UOP + UIP, P, atol=1.0e-14)
        end
        for barrier_level in [ 1.25, 1.20, 1.15, 1.05 ]
            H = DiffFusion.Fixed(barrier_level)
            DOC = DiffFusion.BarrierAssetOption(F, K, H, "DOC", 0.0, 4)(path)
            DIC = DiffFusion.BarrierAssetOption(F, K, H, "DIC", 0.0, 4)(path)
            DOP = DiffFusion.BarrierAssetOption(F, K, H, "DOP", 0.0, 4)(path)
            DIP = DiffFusion.BarrierAssetOption(F, K, H, "DIP", 0.0, 4)(path)
            @test isapprox(DOC + DIC, C, atol=1.0e-14)
            @test isapprox(DOP + DIP, P, atol=1.0e-14)
        end
    end


end
