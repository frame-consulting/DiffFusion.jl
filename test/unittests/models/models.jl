using DiffFusion
using Test

@testset verbose=true "Component and composite models." begin

    @testset "Abstract Model" begin
        struct NoModel <: DiffFusion.Model end
        m = NoModel()
        #
        @test_throws ErrorException DiffFusion.alias(m)
        @test_throws ErrorException DiffFusion.model_alias(m)
        @test_throws ErrorException DiffFusion.state_alias(m)
        @test_throws ErrorException DiffFusion.factor_alias(m)
        @test DiffFusion.parameter_grid(m) == []
        #
        X = [ 11., 12., 13. ] * [ 1 ]'  # (3,1) matrix
        model_state_alias = ["A", "B", "C" ]
        dict = Dict{String, Int}()
        dict["A"] = 2
        dict["B"] = 1
        dict["C"] = 3
        V = DiffFusion.model_state(X, dict)
        @test V("A") == [12.]
        @test V("B") == [11.]
        @test V("C") == [13.]
        #
        dict = DiffFusion.alias_dictionary(model_state_alias)
        V = DiffFusion.model_state(X, dict)
        @test V("A") == [11.]
        @test V("B") == [12.]
        @test V("C") == [13.]
        #
        SX = DiffFusion.model_state(X, DiffFusion.alias_dictionary(model_state_alias))
        #
        @test_throws ErrorException DiffFusion.Theta(m, 1.0, 2.0)
        @test_throws ErrorException DiffFusion.Theta(m, 1.0, 2.0, SX)
        @test_throws ErrorException DiffFusion.state_dependent_Theta(m)
        #
        @test_throws ErrorException DiffFusion.H_T(m, 1.0, 2.0)
        @test_throws ErrorException DiffFusion.H_T(m, 1.0, 2.0, SX)
        @test_throws ErrorException DiffFusion.state_alias_H(m)
        @test_throws ErrorException DiffFusion.state_dependent_H(m)
        #
        @test_throws ErrorException DiffFusion.Sigma_T(m, 1.0, 2.0)
        @test_throws ErrorException DiffFusion.Sigma_T(m, 1.0, 2.0, SX)
        @test_throws ErrorException DiffFusion.factor_alias_Sigma(m)
        @test_throws ErrorException DiffFusion.state_dependent_Sigma(m)
        #
        @test_throws ErrorException DiffFusion.log_asset(m, "alias", 1.0, SX)
        @test_throws ErrorException DiffFusion.log_bank_account(m, "alias", 1.0, SX)
        @test_throws ErrorException DiffFusion.log_zero_bond(m, "alias", 1.0, 2.0, SX)
        @test_throws ErrorException DiffFusion.log_zero_bonds(m, "alias", 1.0, [2.0, 3.0], SX)
        @test_throws ErrorException DiffFusion.log_compounding_factor(m, "alias", 1.0, 2.0, 3.0, SX)
        @test_throws ErrorException DiffFusion.log_asset_convexity_adjustment(m, "dom", "for", "ast", 1.0, 2.0, 3.0, 4.0)
        @test_throws ErrorException DiffFusion.log_future(m, "alias", 1.0, 2.0, SX)
        @test_throws ErrorException DiffFusion.swap_rate_variance(m, "alias", DiffFusion.flat_forward(0.01), 1.0, 2.0, [ 2.0, 3.0, 4.0 ], [1.0, 1.0], SX)
        @test_throws ErrorException DiffFusion.forward_rate_variance(m, "alias", 1.0, 2.0, 3.0, 4.0)
        @test_throws ErrorException DiffFusion.asset_variance(m, "ast", "dom", "for", 1.0, 2.0, SX)
        #
        ch = DiffFusion.correlation_holder("Std")
        @test_throws ErrorException DiffFusion.simulation_parameters(m, ch, 1.0, 2.0)
        @test_throws ErrorException DiffFusion.diagonal_volatility(m, 1.0, 2.0, SX)
        #
        X = (1:3) * (1.0:4.0)'
        V = DiffFusion.model_state(X, dict)
        @test V("A") == [1.0, 2.0, 3.0,  4.0]
        @test V("B") == [2.0, 4.0, 6.0,  8.0]
        @test V("C") == [3.0, 6.0, 9.0, 12.0]
        #
        @test_throws ErrorException DiffFusion.log_asset(m, "alias", 1.0, V)
        @test_throws ErrorException DiffFusion.log_bank_account(m, "alias", 1.0, V)
        @test_throws ErrorException DiffFusion.log_zero_bond(m, "alias", 1.0, 2.0, V)
    end

    include("asset/asset.jl")
    include("credit/credit.jl")
    include("futures/futures.jl")
    include("hybrid/hybrid.jl")
    include("inflation/inflation.jl")
    include("rates/rates.jl")

end
