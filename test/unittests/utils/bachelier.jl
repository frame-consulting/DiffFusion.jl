using DiffFusion
using Distributions
using Test

@testset "Bachelier model." begin
    # We test versus QuantLib values.

    @testset "Bachelier formula" begin
        F = [ 0.50, 0.75, 1.00, 1.50, 2.00 ] * 1.0e-2
        σ = [ 50.0, 50.0, 50.0, 50.0, 50.0 ] * 1.0e-4
        K = 1.0 * 1.0e-2
        T = 5.0
        C = DiffFusion.bachelier_price(K, F, σ, T, +1)
        P = DiffFusion.bachelier_price(K, F, σ, T, -1)
        C_ref = [
            0.0023990535,
            0.0033213557,
            0.0044603103,
            0.0073990535,
            0.0111343686,
        ]
        P_ref = [
            0.0073990535,
            0.0058213557,
            0.0044603103,
            0.0023990535,
            0.0011343686,
        ]
        @test isapprox(C, C_ref, atol=1.0e-10)
        @test isapprox(P, P_ref, atol=1.0e-10)
        #
        F = [ 1.00, 1.00, 1.00, 1.00, 1.00 ] * 1.0e-2
        K = 1.0 * 1.0e-2
        ν = [ -1.0, 0.0, 1.0e-8, 1.0e-6, 1.0e-4 ]
        C = DiffFusion.bachelier_price(K, F, ν, +1)
        P = DiffFusion.bachelier_price(K, F, ν, -1)
        CP_ref = [
            0.0,
            0.0,
            0.0000000040,
            0.0000003989,
            0.0000398942,
        ]
        @test isapprox(C, CP_ref, atol=1.0e-10)
        @test isapprox(P, CP_ref, atol=1.0e-10)
    end

    @testset "Bachelier Vega" begin
        F = [ 0.50, 0.75, 1.00, 1.50, 2.00 ] * 1.0e-2
        σ = [ 50.0, 50.0, 50.0, 50.0, 50.0 ] * 1.0e-4
        K = 0.90 * 1.0e-2
        T = 5.0
        #
        V1 = DiffFusion.bachelier_vega(K, F, σ * sqrt(T) )
        V2 = DiffFusion.bachelier_vega(K, F, σ, T )
        @test V2 == V1 * sqrt(T)
        #
        eps = 1.0e-8
        C1 = DiffFusion.bachelier_price(K, F, σ .+ eps, T, +1)
        C2 = DiffFusion.bachelier_price(K, F, σ .- eps, T, +1)
        P1 = DiffFusion.bachelier_price(K, F, σ .+ eps, T, -1)
        P2 = DiffFusion.bachelier_price(K, F, σ .- eps, T, -1)
        V_C = (C1 - C2) / 2 / eps
        V_P = (P1 - P2) / 2 / eps
        @test isapprox(V2, V_C, atol=2.0e-10)
        @test isapprox(V2, V_P, atol=2.0e-10)
        #
        F = [ 1.00, 1.00, 1.00, 1.00, 1.00 ] * 1.0e-2
        K = 1.0 * 1.0e-2
        ν = [ -1.0, 0.0, 1.0e-8, 1.0e-6, 1.0e-4 ]
        V3 = DiffFusion.bachelier_vega(K, F, ν )
        V3_ref = [
            0.0,
            0.0,
            pdf(Normal(), 0.0),
            pdf(Normal(), 0.0),
            pdf(Normal(), 0.0),
        ]
        @test V3 == V3_ref
    end

    @testset "Bachelier implied volatility" begin
        F_ = [ 0.50, 0.75, 1.00, 1.50, 2.00 ] * 1.0e-2
        K = 1.0 * 1.0e-2
        T = 5.0
        C_ = [
            0.0023990535,
            0.0033213557,
            0.0044603103,
            0.0073990535,
            0.0111343686,
        ]
        P_ = [
            0.0073990535,
            0.0058213557,
            0.0044603103,
            0.0023990535,
            0.0011343686,
        ]
        σ_1 = [ DiffFusion.bachelier_implied_stdev(C, K, F, +1) for (C,F) in zip(C_,F_) ] ./ sqrt(T)
        σ_2 = [ DiffFusion.bachelier_implied_stdev(P, K, F, -1) for (P,F) in zip(P_,F_) ] ./ sqrt(T)
        σ_3 = [ DiffFusion.bachelier_implied_volatility(C, K, F, T, +1) for (C,F) in zip(C_,F_) ]
        σ_4 = [ DiffFusion.bachelier_implied_volatility(P, K, F, T, -1) for (P,F) in zip(P_,F_) ]
        @test isapprox(σ_1, 0.0050 * ones(5), atol=2.0e-10)
        @test isapprox(σ_2, 0.0050 * ones(5), atol=2.0e-10)
        @test isapprox(σ_3, 0.0050 * ones(5), atol=2.0e-10)
        @test isapprox(σ_4, 0.0050 * ones(5), atol=2.0e-10)
    end

end