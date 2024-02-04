
using DiffFusion

using Test

@testset "Test asset model volatility and calibration." begin
    
    if !@isdefined(TestModels)
        include("../../../test_models.jl")
    end

    ch = DiffFusion.correlation_holder("Full")
    #
    DiffFusion.set_correlation!(ch, "USD_f_1", "USD_f_2", 0.8)
    DiffFusion.set_correlation!(ch, "USD_f_2", "USD_f_3", 0.8)
    DiffFusion.set_correlation!(ch, "USD_f_1", "USD_f_3", 0.5)
    #
    DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_2", 0.50)
    #
    DiffFusion.set_correlation!(ch, "EUR-USD_x", "USD_f_1", -0.30)
    DiffFusion.set_correlation!(ch, "EUR-USD_x", "USD_f_2", -0.30)
    DiffFusion.set_correlation!(ch, "EUR-USD_x", "USD_f_3", -0.30)
    #
    DiffFusion.set_correlation!(ch, "EUR-USD_x", "EUR_f_1", -0.20)
    DiffFusion.set_correlation!(ch, "EUR-USD_x", "EUR_f_2", -0.20)
    #
    DiffFusion.set_correlation!(ch, "USD_f_1", "EUR_f_1", 0.30)
    DiffFusion.set_correlation!(ch, "USD_f_2", "EUR_f_2", 0.30)
    #
    DiffFusion.set_correlation!(ch, "EUR-USD_x", "SXE50_x", 0.70)

    @testset "Test asset model variance." begin
        models = TestModels.setup_models(ch)
        ast_model = models[2]
        dom_model = models[1]
        for_model = models[3]
        #
        ν0² = DiffFusion.asset_variance(ast_model, nothing, nothing, ch, 1.0, 5.0)
        @test(sqrt(ν0² / 4.0) == 0.15)
        #
        ν1² = DiffFusion.asset_variance(ast_model, dom_model, nothing, ch, 1.0, 5.0)
        @test(sqrt(ν1² / 4.0) ≤ 0.15)
        #
        ν2² = DiffFusion.asset_variance(ast_model, nothing, for_model, ch, 1.0, 5.0)
        @test(sqrt(ν2² / 4.0) ≥ 0.15)
        #
        ν3² = DiffFusion.asset_variance(ast_model, dom_model, for_model, ch, 1.0, 5.0)
        @test(ν1² ≤ ν3²)
        @test(ν3² ≤ ν2²)
    end

    @testset "Test asset model implied volatilities." begin
        models = TestModels.setup_models(ch)
        ast_model = models[2]
        dom_model = models[1]
        for_model = models[3]
        #
        option_times = [ 2.0, 5.0, 10.0 ]
        #
        σ0 = DiffFusion.model_implied_volatilties(ast_model, nothing, nothing, ch, option_times)
        @test σ0 == 0.15 * ones(3)
        #
        σ1 = DiffFusion.model_implied_volatilties(ast_model, dom_model, nothing, ch, option_times)
        @test all(σ1 .≤ σ0  )
        #
        σ2 = DiffFusion.model_implied_volatilties(ast_model, nothing, for_model, ch, option_times)
        @test all(σ2 .≥ σ0  )
        #
        σ3 = DiffFusion.model_implied_volatilties(ast_model, dom_model, for_model, ch, option_times)
        @test all(σ1 .≤ σ3  )
        @test all(σ3 .≤ σ2  )
    end

    @testset "Test asset model calibration." begin
        models = TestModels.setup_models(ch)
        ast_model = models[2]
        dom_model = models[1]
        for_model = models[3]
        #
        option_times = [ 2.0, 5.0, 10.0 ]
        asset_volatilities = [ 0.15, 0.15, 0.15 ]
        #
        (m, fit) = DiffFusion.lognormal_asset_model(DiffFusion.alias(ast_model), nothing, nothing, ch, option_times, asset_volatilities)
        #println(m.sigma_x.values)
        #println(fit)
        @test isapprox(fit, zeros(3), atol=1.0e-14)
        #
        (m, fit) = DiffFusion.lognormal_asset_model(DiffFusion.alias(ast_model), dom_model, nothing, ch, option_times, asset_volatilities)
        #println(m.sigma_x.values)
        #println(fit)
        @test isapprox(fit, zeros(3), atol=1.0e-14)
        #
        (m, fit) = DiffFusion.lognormal_asset_model(DiffFusion.alias(ast_model), nothing, for_model, ch, option_times, asset_volatilities)
        #println(m.sigma_x.values)
        #println(fit)
        @test isapprox(fit, zeros(3), atol=1.0e-14)
        #
        (m, fit) = DiffFusion.lognormal_asset_model(DiffFusion.alias(ast_model), dom_model, for_model, ch, option_times, asset_volatilities)
        #println(m.sigma_x.values)
        #println(fit)
        @test isapprox(fit, zeros(3), atol=1.0e-14)
    end


end
