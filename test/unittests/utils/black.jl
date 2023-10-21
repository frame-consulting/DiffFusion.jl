
using DiffFusion
using Test

@testset "Black model." begin
    # We test versus QuantLib values.

    @testset "Black formula" begin
        F = [ 0.50, 0.75, 1.00, 1.50, 2.00 ]
        σ = [ 0.15, 0.15, 0.15, 0.15, 0.15 ]
        K = 1.0        
        T = 5.0
        C = DiffFusion.black_price(K, F, σ, T, +1)
        P = DiffFusion.black_price(K, F, σ, T, -1)
        C_ref = [
            0.0016630714,
            0.0312379808,
            0.1331847149,
            0.5224167704,
            1.0033261428,
        ]
        P_ref = [
            0.5016630714,
            0.2812379808,
            0.1331847149,
            0.0224167704,
            0.0033261428,           
        ]
        @test isapprox(C, C_ref, atol=1.0e-10)
        @test isapprox(P, P_ref, atol=1.0e-10)
        #
        F = [ 1.00, 1.00, 1.00, 1.00, 1.00 ]
        ν = [ -1.0, 0.0, 1.0e-4, 1.0, 2.0 ]
        K = 1.0        
        C = DiffFusion.black_price(K, F, ν, +1)
        P = DiffFusion.black_price(K, F, ν, -1)
        CP_ref = [
            0.0000000000,
            0.0000000000,
            0.0000398942,
            0.3829249225,
            0.6826894921,
        ]
        @test isapprox(C, CP_ref, atol=1.0e-10)
        @test isapprox(P, CP_ref, atol=1.0e-10)
    end

    @testset "Black Delta" begin
        F = [ 0.50, 0.75, 1.00, 1.50, 2.00 ]
        σ = [ 0.15, 0.15, 0.15, 0.15, 0.15 ]
        K = 1.0        
        T = 5.0
        C = DiffFusion.black_delta(K, F, σ, T, +1)
        P = DiffFusion.black_delta(K, F, σ, T, -1)
        C_ref = [
            0.0287914087,
            0.2450979966,
            0.5665923574,
            0.9156771508,
            0.9872673671,
        ]
        P_ref = [
            -0.9712085913,
            -0.7549020034,
            -0.4334076426,
            -0.0843228492,
            -0.0127326329,
        ]
        @test isapprox(C, C_ref, atol=1.0e-10)
        @test isapprox(P, P_ref, atol=1.0e-10)
        #
        F = [ 1.00, 1.00, 1.00, 1.00, 1.00 ]
        ν = [ -1.0, 0.0, 1.0e-4, 1.0, 2.0 ]
        K = 0.99        
        C = DiffFusion.black_delta(K, F, ν, +1)
        P = DiffFusion.black_delta(K, F, ν, -1)
        C_ref = [
            1.0,
            1.0,
            1.0000000000,
            0.6949919011,
            0.8425576344,
        ]
        P_ref = [
            0.0,
            0.0,
            0.0000000000,
            -0.3050080989,
            -0.1574423656,
        ]
        @test isapprox(C, C_ref, atol=1.0e-10)
        @test isapprox(P, P_ref, atol=1.0e-10)        
    end

    @testset "Black Gamma" begin
        F = [ 0.50, 0.75, 1.00, 1.50, 2.00 ]
        σ = [ 0.15, 0.15, 0.15, 0.15, 0.15 ]
        K = 1.0        
        T = 5.0
        V = DiffFusion.black_gamma(K, F, σ, T)
        V_ref = [
            0.3921048650,
            1.2499412490,
            1.1728069703,
            0.3074407118,
            0.0490131081,
        ]
        @test isapprox(V, V_ref, atol=1.0e-10)
        #
        F = [ 1.00, 1.00, 1.00, 1.00, 1.00 ]
        ν = [ -1.0, 0.0, 1.0e-4, 1.0, 2.0 ]
        K = 1.00        
        V = DiffFusion.black_gamma(K, F, ν)
        V_ref = [
            0.0,
            0.0,
            3989.4227990275485,
            0.3520653268,
            0.1209853623,
        ]
        @test isapprox(V, V_ref, atol=1.0e-10)
    end

    @testset "Black Theta" begin
        F = [ 0.50, 0.75, 1.00, 1.50, 2.00 ]
        σ = [ 0.15, 0.15, 0.15, 0.15, 0.15 ]
        K = 1.0        
        T = 5.0
        V = DiffFusion.black_theta(K, F, σ, T)
        V_ref = [
            -0.0011027949,
            -0.0079097845,
            -0.0131940784,
            -0.0077820930,
            -0.0022055899,
        ]
        @test isapprox(V, V_ref, atol=1.0e-10)
        #
        F = [ 1.00, 1.00, 1.00, 1.00, 1.00 ]
        σ = [ -0.10, 0.00, 1.e-6, 0.10, 0.20 ]
        T = 5.0
        K = 1.00        
        V = DiffFusion.black_theta(K, F, σ, T)
        V_ref = [
            0.0,
            0.0,
            -0.0000000892,
            -0.0088650406,
            -0.0174007393,
        ]
        @test isapprox(V, V_ref, atol=1.0e-10)
    end

    @testset "Black Vega" begin
        F = [ 0.50, 0.75, 1.00, 1.50, 2.00 ]
        σ = [ 0.15, 0.15, 0.15, 0.15, 0.15 ]
        K = 1.0        
        T = 5.0
        V = DiffFusion.black_vega(K, F, σ, T)
        V_ref = [
            0.0735196622,
            0.5273189644,
            0.8796052278,
            0.5188062012,
            0.1470393244,
        ]
        @test isapprox(V, V_ref, atol=1.0e-10)
        #
        F = [ 1.00, 1.00, 1.00, 1.00, 1.00 ]
        ν = [ -1.0, 0.0, 1.0e-4, 1.0, 2.0 ]
        K = 1.00
        V = DiffFusion.black_vega(K, F, ν)
        V_ref = [
            0.3989422804014327,
            0.3989422804014327,
            0.3989422799,
            0.3520653268,
            0.2419707245,
        ]
        @test isapprox(V, V_ref, atol=1.0e-10)
    end

    @testset "Black implied volatility" begin
        F_ = [ 0.50, 0.75, 1.00, 1.50, 2.00 ]
        K = 1.0        
        T = 5.0
        C_ = [
            0.0016630714,
            0.0312379808,
            0.1331847149,
            0.5224167704,
            1.0033261428,
        ]
        P_ = [
            0.5016630714,
            0.2812379808,
            0.1331847149,
            0.0224167704,
            0.0033261428,           
        ]
        σ_1 = [ DiffFusion.black_implied_stdev(C, K, F, +1) for (C,F) in zip(C_,F_) ] ./ sqrt(T)
        σ_2 = [ DiffFusion.black_implied_stdev(P, K, F, -1) for (P,F) in zip(P_,F_) ] ./ sqrt(T)
        σ_3 = [ DiffFusion.black_implied_volatility(C, K, F, T, +1) for (C,F) in zip(C_,F_) ]
        σ_4 = [ DiffFusion.black_implied_volatility(P, K, F, T, -1) for (P,F) in zip(P_,F_) ]
        @test isapprox(σ_1, 0.15 * ones(5), atol=1.0e-10)
        @test isapprox(σ_2, 0.15 * ones(5), atol=1.0e-10)
        @test isapprox(σ_3, 0.15 * ones(5), atol=1.0e-10)
        @test isapprox(σ_4, 0.15 * ones(5), atol=1.0e-10)
    end
end
