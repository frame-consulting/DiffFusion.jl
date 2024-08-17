
using DiffFusion

using Test

@testset "Black-Scholes single barrier pricing." begin
# We test versus QuantLib values.

    @testset "Vanilla Black-Scholes formula" begin
        S = 100.0
        X = [ 90.0, 100.0, 110.0 ]
        T = 2.0
        r = 0.08
        b = 0.04
        σ = 0.25
        #
        DF_r = exp(-r*T)
        DF_b = exp(-b*T)
        F = S ./ DF_b
        #
        C_BK = DF_r * DiffFusion.black_price(X, F, σ, T, +1)
        P_BK = DF_r * DiffFusion.black_price(X, F, σ, T, -1)
        C_BS = DiffFusion.black_scholes_vanilla_price(X, +1, S, DF_r, DF_b, σ * sqrt(T))
        P_BS = DiffFusion.black_scholes_vanilla_price(X, -1, S, DF_r, DF_b, σ * sqrt(T))
        @test C_BS == C_BK
        @test P_BS == P_BK
    end

    @testset "Haug Barrier options" begin
        # Haug, Table 4-13, p. 154
        S = 100  # spot
        K = 3    # rebate
        T = 0.5  # time to maturity
        r = 0.08
        b = 0.04
        σ1 = 0.25
        σ2 = 0.30
        #
        DF_r = exp(-r*T)
        DF_b = exp(-b*T)
        #
        data = [
            # type,   X,   H,  ---  Price  ---
            #                  σ=0.25,  σ=0.30
            #
            ["DOC",  90,  95,  9.0246,  8.8334, ],
            ["DOC", 100,  95,  6.7924,  7.0285, ],
            ["DOC", 110,  95,  4.8759,  5.4137, ],
            ["DOC",  90, 100,  3.0000,  3.0000, ],
            ["DOC", 100, 100,  3.0000,  3.0000, ],
            ["DOC", 110, 100,  3.0000,  3.0000, ],
            #
            ["UOC",  90, 105,  2.6789,  2.6341, ],
            ["UOC", 100, 105,  2.3580,  2.4389, ],
            ["UOC", 110, 105,  2.3453,  2.4315, ],
            #
            #
            ["DOP",  90,  95,  2.2798,  2.4170, ],
            ["DOP", 100,  95,  2.2947,  2.4258, ],
            ["DOP", 110,  95,  2.6252,  2.6246, ],
            ["DOP",  90, 100,  3.0000,  3.0000, ],
            ["DOP", 100, 100,  3.0000,  3.0000, ],
            ["DOP", 110, 100,  3.0000,  3.0000, ],
            #
            ["UOP",  90, 105,  3.7760,  4.2293, ],
            ["UOP", 100, 105,  5.4932,  5.8032, ],
            ["UOP", 110, 105,  7.5187,  7.5649, ],
            #
            #
            ["DIC",  90,  95,  7.7627,  9.0093, ],
            ["DIC", 100,  95,  4.0109,  5.1370, ],
            ["DIC", 110,  95,  2.0576,  2.8517, ],
            ["DIC",  90, 100, 13.8333, 14.8816, ],
            ["DIC", 100, 100,  7.8494,  9.2045, ],
            ["DIC", 110, 100,  3.9795,  5.3043, ],
            #
            ["UIC",  90, 105, 14.1112, 15.2098, ],
            ["UIC", 100, 105,  8.4482,  9.7278, ],
            ["UIC", 110, 105,  4.5910,  5.8350, ],
            #
            #
            ["DIP",  90,  95,  2.9586,  3.8769, ],
            ["DIP", 100,  95,  6.5677,  7.7989, ],
            ["DIP", 110,  95, 11.9752, 13.3078, ],
            ["DIP",  90, 100,  2.2845,  3.3328, ],
            ["DIP", 100, 100,  5.9085,  7.2636, ],
            ["DIP", 110, 100, 11.6465, 12.9713, ],
            #
            ["UIP",  90, 105,  1.4653,  2.0658, ],
            ["UIP", 100, 105,  3.3721,  4.4226, ],
            ["UIP", 110, 105,  7.0846,  8.3686, ],
        ]
        for d in data
            V1 = DiffFusion.black_scholes_barrier_price(d[2], d[3], K, d[1], S, DF_r, DF_b, σ1, T)
            V2 = DiffFusion.black_scholes_barrier_price(d[2], d[3], K, d[1], S, DF_r, DF_b, σ2, T)
            @test isapprox(V1, d[4], atol=1.0e-4)
            @test isapprox(V2, d[5], atol=1.0e-4)
        end
    end

    @testset "Broadcasting" begin
        S = [ 90, 95, 100, 110, 120 ]
        K = 0    # rebate
        T = 0.5  # time to maturity
        r = 0.08
        b = 0.04
        σ1 = 0.25
        σ2 = 0.30
        #
        DF_r = exp(-r*T)
        DF_b = exp(-b*T)
        #
        X = 100
        H = 90
        V = DiffFusion.black_scholes_barrier_price(X, H, K, "DOP", S, DF_r, DF_b, σ1, T)
        V_ref = [
            0.0,
            0.1290974204294102,
            0.2201391042455878,
            0.2636825755986192,
            0.19373974928092275
        ]
        @test isapprox(V, V_ref, atol=1.e-14)
        #
        S = 100
        X = 90   # strike
        H = 105  # barrier
        K = 3    # rebate
        σ = [ 0.25, 0.30 ]
        V = DiffFusion.black_scholes_barrier_price(X, H, K, "UIP", S, DF_r, DF_b, σ, T)
        V_ref = [
            1.4653126853069676,
            2.0658325935176096,
        ]
        @test isapprox(V, V_ref, atol=1.e-14)
    end

    @testset "Consistency with Vanilla option" begin
        # Haug, Table 4-13, p. 154
        S = 100  # spot
        X = 100  # strike
        K = 0    # rebate
        T = 0.5  # time to maturity
        r = 0.08
        b = 0.04
        σ1 = 0.25
        σ2 = 0.30
        #
        DF_r = exp(-r*T)
        DF_b = exp(-b*T)
        #
        C = DiffFusion.black_scholes_vanilla_price(X, +1, S, DF_r, DF_b, σ1 * sqrt(T))
        P = DiffFusion.black_scholes_vanilla_price(X, -1, S, DF_r, DF_b, σ1 * sqrt(T))
        for H in [ 95, 100, 110, 120, 150, ]
            UOC = DiffFusion.black_scholes_barrier_price(X, H, K, "UOC", S, DF_r, DF_b, σ1, T)
            UIC = DiffFusion.black_scholes_barrier_price(X, H, K, "UIC", S, DF_r, DF_b, σ1, T)
            UOP = DiffFusion.black_scholes_barrier_price(X, H, K, "UOP", S, DF_r, DF_b, σ1, T)
            UIP = DiffFusion.black_scholes_barrier_price(X, H, K, "UIP", S, DF_r, DF_b, σ1, T)
            # println(string(UOC) * ", " * string(UIC))
            # println(string(UOP) * ", " * string(UIP))
            @test isapprox(UOC + UIC, C, atol=1.0e-14)
            @test isapprox(UOP + UIP, P, atol=1.0e-14)
        end
        for H in [ 105, 100, 90, 80, 50, ]
            DOC = DiffFusion.black_scholes_barrier_price(X, H, K, "DOC", S, DF_r, DF_b, σ1, T)
            DIC = DiffFusion.black_scholes_barrier_price(X, H, K, "DIC", S, DF_r, DF_b, σ1, T)
            DOP = DiffFusion.black_scholes_barrier_price(X, H, K, "DOP", S, DF_r, DF_b, σ1, T)
            DIP = DiffFusion.black_scholes_barrier_price(X, H, K, "DIP", S, DF_r, DF_b, σ1, T)
            # println(string(DOC) * ", " * string(DIC))
            # println(string(DOP) * ", " * string(DIP))
            @test isapprox(DOC + DIC, C, atol=1.0e-14)
            @test isapprox(DOP + DIP, P, atol=1.0e-14)
        end
    end
end
