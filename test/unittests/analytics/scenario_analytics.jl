
using DiffFusion
using Random
using StatsBase
using Test

@testset "Scenario generation and analytics." begin

    # hybrid model

    _empty_key = DiffFusion._empty_context_key

    ch = DiffFusion.correlation_holder("Std")

    sigma_fx = DiffFusion.flat_volatility("EUR-USD", 0.15)
    fx_model = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)

    sigma_fx = DiffFusion.flat_volatility("SXE50", 0.10)
    eq_model = DiffFusion.lognormal_asset_model("SXE50-EUR", sigma_fx, ch, fx_model)

    delta_dom = DiffFusion.flat_parameter([ 1., 7., 15. ])
    chi_dom = DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ])
    times_dom =  [ 0. ]
    values_dom = [ 50. 60. 70. ]' * 1.0e-4
    sigma_f_dom = DiffFusion.backward_flat_volatility("USD",times_dom,values_dom)
    hjm_model_dom = DiffFusion.gaussian_hjm_model("USD",delta_dom,chi_dom,sigma_f_dom,ch,nothing)

    delta_for = DiffFusion.flat_parameter([ 1., 10. ])
    chi_for = DiffFusion.flat_parameter([ 0.01, 0.15 ])
    times_for =  [ 0. ]
    values_for = [ 80. 90. ]' * 1.0e-4
    sigma_f_for = DiffFusion.backward_flat_volatility("EUR",times_for,values_for)
    hjm_model_for = DiffFusion.gaussian_hjm_model("EUR",delta_for,chi_for,sigma_f_for,ch,fx_model)

    m = DiffFusion.simple_model("Std", [ hjm_model_dom, fx_model, hjm_model_for, eq_model ])

    # valuation context with deterministic dividend yield

    context = DiffFusion.Context("Std",
        DiffFusion.NumeraireEntry("USD", "USD", Dict(_empty_key => "USD")),
        Dict{String, DiffFusion.RatesEntry}([
            ("USD",   DiffFusion.RatesEntry("USD", "USD", Dict(_empty_key => "USD", "OIS" => "USD", "NO" => "ZERO"))),
            ("EUR",   DiffFusion.RatesEntry("EUR", "EUR", Dict(_empty_key => "EUR", "NO" => "ZERO"))),
            ("SXE50", DiffFusion.RatesEntry("SXE50", nothing, Dict(_empty_key => "SXE50"))),
        ]),
        Dict{String, DiffFusion.AssetEntry}([
            ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", "USD", "EUR", "EUR-USD", Dict(_empty_key => "USD"), Dict(_empty_key => "EUR"))),
            ("SXE50",   DiffFusion.AssetEntry("SXE50", "SXE50-EUR", "EUR", nothing, "SXE50-EUR", Dict(_empty_key => "EUR"), Dict(_empty_key => "SXE50"))),
        ]),
        Dict{String, DiffFusion.ForwardIndexEntry}(),
        Dict{String, DiffFusion.FutureIndexEntry}(),
        Dict{String, DiffFusion.FixingEntry}([
            ("SOFR", DiffFusion.FixingEntry("SOFR", "USD-SOFR-Fixings")),
        ]),
    )

    # term structures
    ts = [
        DiffFusion.flat_forward("USD", 0.03),
        DiffFusion.flat_forward("EUR", 0.02),
        DiffFusion.flat_forward("SXE50", 0.01),
        DiffFusion.flat_parameter("EUR-USD", 1.25),
        DiffFusion.flat_parameter("SXE50-EUR", 3750.00),
        DiffFusion.flat_forward("ZERO", 0.00),
        DiffFusion.flat_parameter("USD-SOFR-Fixings", 0.0123),
    ]

    # swap legs

    leg1 = DiffFusion.cashflow_leg(
        "EUR-leg",
        [
            DiffFusion.FixedCashFlow(1.0, 0.01),
            DiffFusion.FixedCashFlow(2.0, 0.01),
            DiffFusion.FixedCashFlow(3.0, 0.01),
            DiffFusion.FixedCashFlow(4.0, 0.01),
        ],
        [
            100.,
            100.,
            100.,
            100.,
        ],
        "EUR",
        "EUR-USD",
    )
    leg2 = DiffFusion.cashflow_leg(
        "USD-leg",
        [
            DiffFusion.FixedCashFlow(1.0, 0.01),
            DiffFusion.FixedCashFlow(2.0, 0.02),
            DiffFusion.FixedCashFlow(3.0, 0.01),
            DiffFusion.FixedCashFlow(4.0, 0.01),
        ],
        [
            100.,
            100.,
            100.,
            100.,
        ],
        "USD",
        nothing,
        -1.0,
    )

    
    @testset "Scenario generation" begin
        times = 0.0:1.0:10.0
        n_paths = 2^3
        sim = DiffFusion.simple_simulation(m, ch, times, n_paths, with_progress_bar = false)
        path_ = DiffFusion.path(sim, ts, context, DiffFusion.LinearPathInterpolation)
        #
        obs_times = 1:0.5:10
        scens = DiffFusion.scenarios([leg1, leg2], obs_times, path_, "", with_progress_bar = false)
        @test size(scens.X) == (n_paths, length(obs_times), 2)
        #
        path_ = DiffFusion.path(sim, ts, context, DiffFusion.NoPathInterpolation)
        @test_throws AssertionError DiffFusion.scenarios([leg1, leg2], obs_times, path_, "", with_progress_bar = false)
    end

    @testset "Analytics application" begin
        times = 0.0:1.0:5.0
        n_paths = 2^3
        sim = DiffFusion.simple_simulation(m, ch, times, n_paths, with_progress_bar = false)
        path_ = DiffFusion.path(sim, ts, context, DiffFusion.LinearPathInterpolation)
        scens = DiffFusion.scenarios([leg1, leg2], times, path_, "", with_progress_bar = true)
        #
        average_paths = false
        aggregate_legs = false
        scens_agg = DiffFusion.aggregate(scens, average_paths, aggregate_legs)
        @test scens_agg == scens
        #
        average_paths = true
        aggregate_legs = false
        scens_agg = DiffFusion.aggregate(scens, average_paths, aggregate_legs)
        @test size(scens_agg.X) == (1,length(times),2)
        #
        average_paths = false
        aggregate_legs = true
        scens_agg = DiffFusion.aggregate(scens, average_paths, aggregate_legs)
        @test size(scens_agg.X) == (n_paths,length(times),1)
        # display(scens_agg.X[:,:,1]')
        #
        average_paths = true
        aggregate_legs = true
        scens_agg = DiffFusion.aggregate(scens, average_paths, aggregate_legs)
        @test size(scens_agg.X) == (1,length(times),1)
        #
        gross_leg = true
        average_paths = false
        aggregate_legs = false
        scens_ee = DiffFusion.expected_exposure(scens, gross_leg, average_paths, aggregate_legs)
        @test all(scens_ee.X .>= 0.0)
        #
        gross_leg = false
        average_paths = false
        aggregate_legs = false
        scens_ee = DiffFusion.expected_exposure(scens, gross_leg, average_paths, aggregate_legs)
        @test !all(scens_ee.X .>= 0.0)
        #
        scens_ee = DiffFusion.expected_exposure(scens, gross_leg, average_paths, aggregate_legs)
        @test DiffFusion.expected_exposure(scens, gross_leg, true, false).X == DiffFusion.aggregate(scens_ee, true, false).X
        @test DiffFusion.expected_exposure(scens, gross_leg, false, true).X == DiffFusion.aggregate(scens_ee, false, true).X
        @test DiffFusion.expected_exposure(scens, gross_leg, true, true).X == DiffFusion.aggregate(scens_ee, true, true).X
        #
        @test scens_ee.leg_aliases == ["EE[EUR-leg]", "EE[USD-leg]"]
        # display(scens_ee.X)
    end

    @testset "PFE calculation" begin
        times = 0.0:2.0:10.0
        X = reshape(hcat((0.0:1.0:10 for k in 1:6)...), (11, 6, 1))
        scens = DiffFusion.ScenarioCube(X, times, ["OneTo(10)"], "", nothing)
        pfe = DiffFusion.potential_future_exposure(scens, 0.9)
        @test pfe.X == 9.0 * ones(1, 6, 1)
        @test pfe.leg_aliases == ["Q_0.90[EE[OneTo(10)]]"]
    end

    @testset "XVA calculation" begin
        times = 0.0:2.0:10.0
        X = reshape(hcat((0.0:1.0:10 for k in 1:6)...), (11, 6, 1)) .- 3.0
        scens = DiffFusion.ScenarioCube(X, times, ["OneTo(10)"], "", nothing)
        # display(scens.X)
        ts = DiffFusion.flat_spread_curve(0.03)
        # CVA
        cva = DiffFusion.valuation_adjustment(
            ts,
            0.4,
            1.0,
            scens,
            false, false, false,
            0.2
        )
        cva_X = sum(cva.X, dims=(2,3))
        # display(cva_X)
        cva_X_ref = [ 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0 ] * (1.0 - exp(-0.3)) * 0.6
        # display(cva_X_ref)
        @test maximum(abs.(cva_X - cva_X_ref)) < 1.0e-14
        @test cva.leg_aliases == ["CVA[OneTo(10)]"]
        # DVA
        dva = DiffFusion.valuation_adjustment(
            ts,
            0.4,
            -1.0,
            scens,
            false, false, false,
            0.2
        )
        dva_X = sum(dva.X, dims=(2,3))
        # display(dva_X)
        dva_X_ref = [ -3.0, -2.0, -1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ] * (1.0 - exp(-0.3)) * 0.6
        # display(dva_X_ref)
        @test maximum(abs.(dva_X - dva_X_ref)) < 1.0e-14
        @test dva.leg_aliases == ["DVA[OneTo(10)]"]
    end

    @testset "XVA aggregation" begin
        times = 0.0:2.0:10.0
        Random.seed!(1234)
        X = rand(10, 6, 4) .- 0.5
        scens = DiffFusion.ScenarioCube(X, times, ["A", "B", "C", "D"], "", nothing)
        ts = DiffFusion.flat_spread_curve(0.03)
        rr = 0.4
        rho = 0.5
        # CVA
        cva = DiffFusion.valuation_adjustment(
            ts,
            rr,
            1.0,
            scens,
            false, true, true,
            rho
        )
        # display(cva.X)
        scens_agg = DiffFusion.expected_exposure(scens, false, true, true,)
        cva_agg = DiffFusion.valuation_adjustment(
            ts,
            rr,
            1.0,
            scens_agg,
            true, false, false,
            rho
        )
        # display(cva_agg.X)
        @test maximum(abs.(cva_agg.X - cva.X)) < 1.0e-14
    end

end
