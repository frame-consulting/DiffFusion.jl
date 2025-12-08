using DiffFusion
using Test

@testset "Ornstein-Uhlenbeck model methods." begin
    
    times =  [ 1., 2., 5., 10. ]
    values = [ 15. 10. 20. 30.; ]
    chi = DiffFusion.flat_parameter("Std", 0.10)
    sigma_x = DiffFusion.backward_flat_volatility("Std",times,values)

    @testset "Model setup." begin
        m = DiffFusion.ornstein_uhlenbeck_model("OU", chi, sigma_x)
        @test DiffFusion.alias(m) == "OU"
        @test DiffFusion.state_alias(m) == [ "OU_x" ]
        @test DiffFusion.factor_alias(m) == [ "OU_x" ]
        @test DiffFusion.state_alias_H(m) == [ "OU_x" ]
        @test DiffFusion.factor_alias_Sigma(m) == [ "OU_x" ]
        @test DiffFusion.state_dependent_Theta(m) == false
        @test DiffFusion.state_dependent_H(m) == false
        @test DiffFusion.state_dependent_Sigma(m) == false
    end

    @testset "Model functions." begin
        m = DiffFusion.ornstein_uhlenbeck_model("OU", chi, sigma_x)
        #
        @test DiffFusion.Theta(m, 0.0, 1.0) == zeros(1)
        @test DiffFusion.H_T(m, 1.0, 2.0) == exp(-0.1) * ones(1,1)
        #
        @test DiffFusion.Sigma_T(m, 0.5, 12.5)(0.5) == exp(-0.10 * 12.0) * 15. * ones(1,1)
        @test DiffFusion.Sigma_T(m, 0.5, 12.5)(5.0) == exp(-0.10 *  7.5) * 20. * ones(1,1)
        @test DiffFusion.Sigma_T(m, 0.5, 12.5)(9.0) == exp(-0.10 *  3.5) * 30. * ones(1,1)
        @test DiffFusion.Sigma_T(m, 0.5, 12.5)(11.0) == exp(-0.10 * 1.5) * 30. * ones(1,1)
        #
        @test DiffFusion.simulation_parameters(m, nothing, 2.0, 3.0) == nothing
    end

    @testset "Covariance calculation" begin
        m = DiffFusion.ornstein_uhlenbeck_model("OU", chi, sigma_x)
        @test DiffFusion.covariance(m, nothing, 0.0, 1.0, nothing) == reshape([ (1. - exp(-2*0.1)) / (2*0.1) * 225.], (1,1))
    end

    @testset "Access model state variables" begin
        m = DiffFusion.ornstein_uhlenbeck_model("OU", chi, sigma_x)
        dict = DiffFusion.alias_dictionary(DiffFusion.state_alias(m))
        X = [ 1. ] * [ 1., 2., 3. ]'
        SX = DiffFusion.model_state(X, dict)
        @test SX("OU_x") == reshape(X, 3)
        @test_throws ErrorException DiffFusion.log_asset(m, DiffFusion.alias(m), 1.0, SX)
        @test_throws ErrorException DiffFusion.log_bank_account(m, DiffFusion.alias(m), 1.0, SX)
        @test_throws ErrorException DiffFusion.log_zero_bond(m, DiffFusion.alias(m), 1.0, 2.0, SX)
    end

end
