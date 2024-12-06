
using DiffFusion
using Test

@testset "Covariance calculation for reference rates." begin

    ch_one = DiffFusion.correlation_holder("One")
    #
    get_correlation(alias::String) = begin
        ch = DiffFusion.correlation_holder(alias)
        #
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_2", 0.5)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "EUR_f_3", 0.5)
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_3", 0.2)
        #
        DiffFusion.set_correlation!(ch, "USD_f_1", "USD_f_2", 0.5)
        DiffFusion.set_correlation!(ch, "USD_f_2", "USD_f_3", 0.5)
        DiffFusion.set_correlation!(ch, "USD_f_1", "USD_f_3", 0.2)
        #
        DiffFusion.set_correlation!(ch, "GBP_f_1", "GBP_f_2", 0.5)
        DiffFusion.set_correlation!(ch, "GBP_f_2", "GBP_f_3", 0.5)
        DiffFusion.set_correlation!(ch, "GBP_f_1", "GBP_f_3", 0.2)
        #
        #
        DiffFusion.set_correlation!(ch, "EUR_f_1", "USD-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "USD-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "EUR_f_3", "USD-EUR_x", 0.1)
        #
        DiffFusion.set_correlation!(ch, "USD_f_1", "USD-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "USD_f_2", "USD-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "USD_f_3", "USD-EUR_x", 0.1)
        #
        DiffFusion.set_correlation!(ch, "GBP_f_1", "USD-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "GBP_f_2", "USD-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "GBP_f_3", "USD-EUR_x", 0.1)
        #
        DiffFusion.set_correlation!(ch, "EUR_f_1", "GBP-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "GBP-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "EUR_f_3", "GBP-EUR_x", 0.1)
        #
        DiffFusion.set_correlation!(ch, "USD_f_1", "GBP-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "USD_f_2", "GBP-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "USD_f_3", "GBP-EUR_x", 0.1)
        #
        DiffFusion.set_correlation!(ch, "GBP_f_1", "GBP-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "GBP_f_2", "GBP-EUR_x", 0.1)
        DiffFusion.set_correlation!(ch, "GBP_f_3", "GBP-EUR_x", 0.1)
        #
        #
        DiffFusion.set_correlation!(ch, "USD-EUR_x", "GBP-EUR_x", 0.1)
        #
        #
        DiffFusion.set_correlation!(ch, "EUR_f_1", "USD_f_1", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_1", "USD_f_2", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_1", "USD_f_3", 0.2)
        #
        DiffFusion.set_correlation!(ch, "EUR_f_2", "USD_f_1", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "USD_f_2", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "USD_f_3", 0.2)
        #
        DiffFusion.set_correlation!(ch, "EUR_f_3", "USD_f_1", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_3", "USD_f_2", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_3", "USD_f_3", 0.2)
        #
        DiffFusion.set_correlation!(ch, "EUR_f_1", "GBP_f_1", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_1", "GBP_f_2", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_1", "GBP_f_3", 0.2)
        #
        DiffFusion.set_correlation!(ch, "EUR_f_2", "GBP_f_1", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "GBP_f_2", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "GBP_f_3", 0.2)
        #
        DiffFusion.set_correlation!(ch, "EUR_f_3", "GBP_f_1", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_3", "GBP_f_2", 0.2)
        DiffFusion.set_correlation!(ch, "EUR_f_3", "GBP_f_3", 0.2)
        #
        DiffFusion.set_correlation!(ch, "USD_f_1", "GBP_f_1", 0.2)
        DiffFusion.set_correlation!(ch, "USD_f_1", "GBP_f_2", 0.2)
        DiffFusion.set_correlation!(ch, "USD_f_1", "GBP_f_3", 0.2)
        #
        DiffFusion.set_correlation!(ch, "USD_f_2", "GBP_f_1", 0.2)
        DiffFusion.set_correlation!(ch, "USD_f_2", "GBP_f_2", 0.2)
        DiffFusion.set_correlation!(ch, "USD_f_2", "GBP_f_3", 0.2)
        #
        DiffFusion.set_correlation!(ch, "USD_f_3", "GBP_f_1", 0.2)
        DiffFusion.set_correlation!(ch, "USD_f_3", "GBP_f_2", 0.2)
        DiffFusion.set_correlation!(ch, "USD_f_3", "GBP_f_3", 0.2)
        #
        #
        return ch            
    end

    hybrid_model(ch) = begin
        times = [ 0. ]
        #
        hjm_eur = DiffFusion.gaussian_hjm_model(
            "EUR",
            DiffFusion.flat_parameter([ 1., 10., 20. ]),      # delta
            DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ]),  # chi
            DiffFusion.backward_flat_volatility("",times,[ 60. 60. 60. ]' * 1.0e-4),  # sigma
            ch,
            nothing,
        )
        fx_usd_eur = DiffFusion.lognormal_asset_model(
            "USD-EUR",
            DiffFusion.flat_volatility("", 0.10),
            ch,
            nothing,
        )
        hjm_usd = DiffFusion.gaussian_hjm_model(
            "USD",
            DiffFusion.flat_parameter([ 1., 10., 20. ]),      # delta
            DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ]),  # chi
            DiffFusion.backward_flat_volatility("",times,[ 80. 80. 80. ]' * 1.0e-4),  # sigma
            ch,
            fx_usd_eur,
        )
        fx_gbp_eur = DiffFusion.lognormal_asset_model(
            "GBP-EUR",
            DiffFusion.flat_volatility("", 0.10),
            ch,
            nothing,
        )
        hjm_gbp = DiffFusion.gaussian_hjm_model(
            "GBP",
            DiffFusion.flat_parameter([ 1., 10., 20. ]),      # delta
            DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ]),  # chi
            DiffFusion.backward_flat_volatility("",times,[ 80. 80. 80. ]' * 1.0e-4),  # sigma
            ch,
            fx_gbp_eur,
        )
        #
        models = [ hjm_eur, fx_usd_eur, hjm_usd, fx_gbp_eur, hjm_gbp ]
        return DiffFusion.simple_model("Std", models)
    end
    
    empty_key = DiffFusion._empty_context_key
    #
    ctx = DiffFusion.Context("Std",
        DiffFusion.NumeraireEntry("EUR", "EUR", Dict(empty_key => "yc/EUR:OIS")),
        Dict{String, DiffFusion.RatesEntry}([
            ("EUR", DiffFusion.RatesEntry("EUR","EUR",
                Dict(
                    empty_key => "yc/EUR:OIS",
                ))),
            ("USD", DiffFusion.RatesEntry("USD", "USD",
                Dict(
                    empty_key => "yc/USD:XCY",
                ))),
            ("GBP", DiffFusion.RatesEntry("GBP", "GBP",
                Dict(
                    empty_key => "yc/GBP:XCY",
                ))),
        ]),
        Dict{String, DiffFusion.AssetEntry}([
            ("USD-EUR", DiffFusion.AssetEntry("USD-EUR", "USD-EUR", "EUR", "USD", "pa/USD-EUR",
                Dict(empty_key => "yc/EUR:OIS"), Dict(empty_key => "yc/USD:XCY"))
            ),
            ("GBP-EUR", DiffFusion.AssetEntry("GBP-EUR", "GBP-EUR", "EUR", "GBP", "pa/GBP-EUR",
                Dict(empty_key => "yc/EUR:OIS"), Dict(empty_key => "yc/GBP:XCY"))
            ),
            ]),
        Dict{String, DiffFusion.ForwardIndexEntry}(),
        Dict{String, DiffFusion.FutureIndexEntry}(),
        Dict{String, DiffFusion.FixingEntry}(),
    )
    
    struct NoModel <: DiffFusion.Model end # dummy model for testing

    @testset "Test scaling vector calculation" begin
        ch_full = get_correlation("Std")
        mdl = hybrid_model(ch_full)
        # println(DiffFusion.state_alias(mdl))
        # println(DiffFusion.factor_alias(mdl))
        #
        # test constraints
        @test_throws ErrorException DiffFusion.reference_rate_scaling("NoKey", 1.0, mdl, ctx)
        @test_throws ErrorException DiffFusion.reference_rate_scaling("EUR", 1.0, NoModel(), ctx)
        @test_throws AssertionError DiffFusion.reference_rate_scaling("EUR", -1.0, mdl, ctx)
        @test_throws AssertionError DiffFusion.reference_rate_scaling("USD", 0.0, mdl, ctx)
        @test_throws AssertionError DiffFusion.reference_rate_scaling("USD-EUR", 1.0, mdl, ctx)
        #
        # zero rate scaling
        #
        A = DiffFusion.reference_rate_scaling("EUR", 10.0, mdl, ctx)
        A_ref = vcat(
            [ 0.9516258196404047, 0.6321205588285577, 0.3167376438773787 ],
            zeros(11),
        )
        @test isapprox(A, A_ref, atol=1.0e-14)
        #
        A = DiffFusion.reference_rate_scaling("USD", 2.0, mdl, ctx)
        A_ref = vcat(
            zeros(5),
            [ 0.9900663346622374, 0.9063462346100909, 0.7519806065099559 ],
            zeros(6),
        )
        @test isapprox(A, A_ref, atol=1.0e-14)
        #
        A = DiffFusion.reference_rate_scaling("GBP", 0.25, mdl, ctx)
        A_ref = vcat(
            zeros(10),
            [ 0.9987510410159661, 0.9876035188666954, 0.9634201822859619 ],
            zeros(1),
        )
        @test isapprox(A, A_ref, atol=1.0e-14)
        #
        A = DiffFusion.reference_rate_scaling("EUR", 10.0, mdl.models[1], ctx)
        A_ref = [ 0.9516258196404047, 0.6321205588285577, 0.3167376438773787, 0.0 ]
        @test isapprox(A, A_ref, atol=1.0e-14)
        #
        # FX rate scaling
        #
        A = DiffFusion.reference_rate_scaling("USD-EUR", 0.0, mdl, ctx)
        A_ref = vcat(
            zeros(3),
            [ 1.0, 1.0 ],  # EUR_s, USD-EUR_x
            zeros(3),
            [ -1.0 ], # USD_s
            zeros(5),
        )
        @test A == A_ref
        #
        A = DiffFusion.reference_rate_scaling("GBP-EUR", 0.0, mdl, ctx)
        A_ref = vcat(
            zeros(3),
            [ 1.0  ],  # EUR_s
            zeros(5),
            [ 1.0 ], # GBP-EUR_x
            zeros(3),
            [ -1.0 ], # GBP_s
        )
        @test A == A_ref
        #
        # println(A)
        # println(A_ref)
    end

    @testset "Test scaling matrix calculation" begin
        ch_full = get_correlation("Std")
        mdl = hybrid_model(ch_full)
        #
        A = DiffFusion.reference_rate_scaling(
            [
                ("EUR", 1.0),
                ("GBP-EUR", 0.0),
            ], mdl, ctx)
        A1 = DiffFusion.reference_rate_scaling("EUR", 1.0, mdl, ctx)
        A2 = DiffFusion.reference_rate_scaling("GBP-EUR", 0.0, mdl, ctx)
        @test A == hcat(A1, A2)
        A = DiffFusion.reference_rate_scaling(
            [
                ("EUR", 1.0),
                ("EUR", 5.0),
                ("EUR", 10.0),
                ("USD", 1.0),
                ("USD", 5.0),
                ("USD", 10.0),
                ("GBP", 1.0),
                ("GBP", 5.0),
                ("GBP", 10.0),
                ("USD-EUR", 0.0),
                ("GBP-EUR", 0.0),
            ], mdl, ctx)
        @test size(A) == (14, 11)
        # display(A)
    end

    @testset "Test covariance calculation" begin
        ch_full = get_correlation("Std")
        mdl = hybrid_model(ch_full)
        term = 2.0
        dt = 0.25
        cov = DiffFusion.reference_rate_covariance(
            ("EUR", term),
            ("GBP-EUR", 0.0),
            ctx, mdl, ch_full, 0.0, dt
        )
        var_eur = DiffFusion.reference_rate_covariance(
            ("EUR", term),
            ("EUR", term),
            ctx, mdl, ch_full, 0.0, dt
        )
        var_gbp_eur = DiffFusion.reference_rate_covariance(
            ("GBP-EUR", 0.0),
            ("GBP-EUR", 0.0),
            ctx, mdl, ch_full, 0.0, dt
        )
        @test isapprox(sqrt(var_eur/dt),              0.0059616690952, atol=1.0e-13)  # gbp rates vol with mean reversion
        @test isapprox(sqrt(var_gbp_eur/dt),          0.0999883698958, atol=1.0e-13)  # GBP-EUR fx vol
        @test isapprox(cov/sqrt(var_eur*var_gbp_eur), 0.1060389153917, atol=1.0e-13)  # rates-fx correlation
        #
        C = DiffFusion.reference_rate_covariance(
            [
                ("EUR", term),
                ("GBP-EUR", 0.0),
            ],
            ctx, mdl, ch_full, 0.0, dt
        )
        @test isapprox(C[1,1], var_eur, atol=1.0e-14)
        @test isapprox(C[2,2], var_gbp_eur, atol=1.0e-14)
        @test isapprox(C[1,2], cov, atol=1.0e-14)
    end

    @testset "Test volatility and correlation calculation" begin
        ch_full = get_correlation("Std")
        mdl = hybrid_model(ch_full)
        term = 2.0
        dt = 0.25
        (v, C) = DiffFusion.reference_rate_volatility_and_correlation(
            [
                ("EUR", term),
                ("GBP-EUR", 0.0),
            ],
            ctx, mdl, ch_full, 0.0, dt
        )
        @test isapprox(v[1], 0.0059616690952, atol=1.0e-14)
        @test isapprox(v[2], 0.0999883698958, atol=1.0e-13)
        @test isapprox(C[1,2], 0.1060389153917, atol=1.0e-13)
        #
        (v, C) = DiffFusion.reference_rate_volatility_and_correlation(
            [
                ("EUR", 1.0),
                ("EUR", 5.0),
                ("EUR", 10.0),
                ("USD", 1.0),
                ("USD", 5.0),
                ("USD", 10.0),
                ("GBP", 1.0),
                ("GBP", 5.0),
                ("GBP", 10.0),
                ("USD-EUR", 0.0),
                ("GBP-EUR", 0.0),
            ],
            ctx, mdl, ch_full, 0.0, dt
        )
        v_ref = [
           0.0063136243172781,
           0.0062968279461237,
           0.0063558258150786,
           0.0084181657563708,
           0.0083957705948316,
           0.0084744344201048,
           0.0084181657563708,
           0.0083957705948316,
           0.0084744344201048,
           0.0999883698957685,
           0.0999883698957685,
        ]
        C_ref = [
            1.0       0.71153    0.532939   0.18407    0.180252   0.178836   0.18407    0.180252   0.178836   0.102669   0.102669
            0.71153   1.0        0.965235   0.180252   0.176515   0.175128   0.180252   0.176515   0.175128   0.0961173  0.0961173
            0.532939  0.965235   1.0        0.178836   0.175128   0.173753   0.178836   0.175128   0.173753   0.0935097  0.0935097
            0.18407   0.180252   0.178836   1.0        0.71153    0.532939   0.18407    0.180252   0.178836   0.0858348  0.0954544
            0.180252  0.176515   0.175128   0.71153    1.0        0.965235   0.180252   0.176515   0.175128   0.0899515  0.0934748
            0.178836  0.175128   0.173753   0.532939   0.965235   1.0        0.178836   0.175128   0.173753   0.0917148  0.0927405
            0.18407   0.180252   0.178836   0.18407    0.180252   0.178836   1.0        0.71153    0.532939   0.0954544  0.0858348
            0.180252  0.176515   0.175128   0.180252   0.176515   0.175128   0.71153    1.0        0.965235   0.0934748  0.0899515
            0.178836  0.175128   0.173753   0.178836   0.175128   0.173753   0.532939   0.965235   1.0        0.0927405  0.0917148
            0.102669  0.0961173  0.0935097  0.0858348  0.0899515  0.0917148  0.0954544  0.0934748  0.0927405  1.0        0.0996125
            0.102669  0.0961173  0.0935097  0.0954544  0.0934748  0.0927405  0.0858348  0.0899515  0.0917148  0.0996125  1.0
        ]
        @test isapprox(v, v_ref, atol=1.0e-14)
        @test isapprox(C, C_ref, atol=1.0e-5)
        # display(v)
        # display(C)
    end

    @testset "Test degenerated volatility and correlation calculation" begin
        ch_full = get_correlation("Std")
        times = [ 0. ]
        #
        hjm_eur = DiffFusion.gaussian_hjm_model(
            "EUR",
            DiffFusion.flat_parameter([ 1., 10., 20. ]),      # delta
            DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ]),  # chi
            DiffFusion.backward_flat_volatility("",times,[ 0. 0. 0. ]' * 1.0e-4),  # sigma
            ch_full,
            nothing,
        )
        fx_usd_eur = DiffFusion.lognormal_asset_model(
            "USD-EUR",
            DiffFusion.flat_volatility("", 0.0),
            ch_full,
            nothing,
        )
        hjm_usd = DiffFusion.gaussian_hjm_model(
            "USD",
            DiffFusion.flat_parameter([ 1., 10., 20. ]),      # delta
            DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ]),  # chi
            DiffFusion.backward_flat_volatility("",times,[ 0. 0. 0. ]' * 1.0e-4),  # sigma
            ch_full,
            fx_usd_eur,
        )
        #
        mdl = DiffFusion.simple_model("Std", [ hjm_eur, fx_usd_eur, hjm_usd])
        #
        dt = 0.25
        (v, C) = DiffFusion.reference_rate_volatility_and_correlation(
            [
                ("EUR", 1.0),
                ("EUR", 5.0),
                ("EUR", 10.0),
                ("USD-EUR", 0.0),
            ],
            ctx, mdl, ch_full, 0.0, dt
        )
        #
        v_ref = zeros(4)
        C_ref = [
            1.0 0.0 0.0 0.0
            0.0 1.0 0.0 0.0
            0.0 0.0 1.0 0.0
            0.0 0.0 0.0 1.0
        ]
        @test v == v_ref
        @test C == C_ref
        # display(v)
        # display(C)
    end

end