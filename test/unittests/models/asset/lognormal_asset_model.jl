using DiffFusion
using Test

@testset "Lognormal asset model methods." begin
    
    ch = DiffFusion.correlation_holder("Std")
    DiffFusion.set_correlation!(ch, "EUR-USD_x", "EUR-GBP_x", 0.25)
    times =  [ 1., 2., 5., 10. ]
    values = [ 15. 10. 20. 30.; ]
    sigma_x = DiffFusion.backward_flat_volatility("Std",times,values)

    @testset "Model setup." begin
        m = DiffFusion.lognormal_asset_model("EUR-USD", sigma_x, ch, nothing)
        @test DiffFusion.alias(m) == "EUR-USD"
        @test DiffFusion.state_alias(m) == [ "EUR-USD_x" ]
        @test DiffFusion.factor_alias(m) == [ "EUR-USD_x" ]
        @test DiffFusion.state_alias_H(m) == [ "EUR-USD_x" ]
        @test DiffFusion.factor_alias_Sigma(m) == [ "EUR-USD_x" ]
        @test DiffFusion.state_dependent_Theta(m) == false
        @test DiffFusion.state_dependent_H(m) == false
        @test DiffFusion.state_dependent_Sigma(m) == false
    end

    @testset "Model functions without quanto." begin
        m = DiffFusion.lognormal_asset_model("EUR-USD", sigma_x, ch, nothing)
        #
        vol = DiffFusion.asset_volatility(m, 0.0, 10.0)
        @test vol(0.5) == 15.
        @test vol(1.0) == 15.
        @test vol(1.5) == 10.
        @test vol(12.5) == 30.
        #
        theta = DiffFusion.Theta(m, 0.0, 1.0)
        @test size(theta) == (1,)
        @test theta[1] == -0.5 * 225.
        theta = DiffFusion.Theta(m, 3.0, 8.0)
        theta_ref = -0.5 * (2*400. + 3*900.)
        @test isapprox(theta[1], theta_ref, atol=2.1e-5)
        #
        @test DiffFusion.H_T(m, 0.5, 12.5) == ones(1,1)
        #
        @test DiffFusion.Sigma_T(m, 0.5, 12.5)(0.5) == 15. * ones(1,1)
        @test DiffFusion.Sigma_T(m, 0.5, 12.5)(5.0) == 20. * ones(1,1)
        @test DiffFusion.Sigma_T(m, 0.5, 12.5)(9.0) == 30. * ones(1,1)
        @test DiffFusion.Sigma_T(m, 0.5, 12.5)(11.0) == 30. * ones(1,1)
    end

    @testset "Model Theta with quanto." begin
        qm = DiffFusion.lognormal_asset_model("EUR-GBP", sigma_x, ch, nothing)
        m = DiffFusion.lognormal_asset_model("EUR-USD", sigma_x, ch, qm)
        #
        @test DiffFusion.quanto_drift(["EUR-USD_x"], qm, 0.5, 12.5)(0.5) == [ 0.25 * 15. ]
        @test DiffFusion.quanto_drift(["EUR-USD_x"], qm, 0.5, 12.5)(6.5) == [ 0.25 * 30. ]
        @test DiffFusion.quanto_drift(["EUR-USD_x"], qm, 0.5, 12.5)(10.5) == [ 0.25 * 30. ]
        #
        theta = DiffFusion.Theta(m, 0.0, 1.0)
        @test size(theta) == (1,)
        @test theta[1] == -0.5 * 15. * (15. + 2*0.25*15. )
        #
        theta = DiffFusion.Theta(m, 3.0, 8.0)
        theta_ref = -0.5 * (2. * 20. * (20. + 2*0.25*20.)  + 3. * 30. * (30. + 2*0.25*30.))
        @test isapprox(theta[1], theta_ref, atol=3.1e-5)
        #
    end

    @testset "Covariance calculation" begin
        m = DiffFusion.lognormal_asset_model("EUR-USD", sigma_x, ch, nothing)
        @test DiffFusion.covariance(m,nothing,0.0,1.0,nothing) == reshape([ 225.], (1,1))
        @test isapprox(DiffFusion.covariance(m,nothing,3.0,8.0,nothing)[1,1], 2*400. + 3*900., atol=4.1e-5)
    end

    @testset "Access model state variables" begin
        m = DiffFusion.lognormal_asset_model("EUR-USD", sigma_x, ch, nothing)
        dict = DiffFusion.alias_dictionary(DiffFusion.state_alias(m))
        X = [ 1. ] * [ 1., 2., 3. ]'
        SX = DiffFusion.model_state(X, dict)
        @test DiffFusion.log_asset(m, DiffFusion.alias(m), 1.0, SX) == [ 1., 2., 3. ]
        @test_throws AssertionError DiffFusion.log_asset(m, "USD-EUR", 1.0, SX)
        #
        dict = DiffFusion.alias_dictionary([ "GBP_x_1", "EUR-USD_x", "EUR_GBP_x" ])
        X = [ 1., 2, 3 ] * [ 1., 2., 3. ]'
        SX = DiffFusion.model_state(X, dict)
        @test DiffFusion.log_asset(m, DiffFusion.alias(m), 1.0, SX) == [ 2., 4., 6. ]
        #
        dict = DiffFusion.alias_dictionary([ "GBP_x_1", "EUR-USD_s", "EUR_GBP_x" ])
        X = [ 1., 2, 3 ] * [ 1., 2., 3. ]'
        SX = DiffFusion.model_state(X, dict)
        @test_throws KeyError DiffFusion.log_asset(m, DiffFusion.alias(m), 1.0, SX)
        @test_throws ErrorException DiffFusion.log_bank_account(m, DiffFusion.alias(m), 1.0, SX)
        @test_throws ErrorException DiffFusion.log_zero_bond(m, DiffFusion.alias(m), 1.0, 2.0, SX)
    end

end
