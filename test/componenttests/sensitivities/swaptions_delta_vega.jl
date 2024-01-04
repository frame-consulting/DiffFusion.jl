using DiffFusion
using Test
using UnicodePlots

    
@testset "Test European and Bermudan swaption simulation" begin
    
    # Model
    
    ch = DiffFusion.correlation_holder("")
    δ = DiffFusion.flat_parameter([ 0., ])
    χ = DiffFusion.flat_parameter([ 0.01, ])
    
    times = [  1.,  2.,  5., 10. ]
    values = [ 50.,  50.,  50.,  50., ]' * 1.0e-4 
    σ = DiffFusion.backward_flat_volatility("", times, values)
    
    model = DiffFusion.gaussian_hjm_model("md/EUR", δ, χ, σ, ch, nothing)
    
    
    # Simulation
    
    times = 0.0:0.25:10.0
    n_paths = 2^10
    
    sim = DiffFusion.simple_simulation(
        model,
        ch,
        times,
        n_paths,
        with_progress_bar = true,
        brownian_increments = DiffFusion.sobol_brownian_increments,
    )
    
    
    # Path
    
    yc_estr = DiffFusion.linear_zero_curve(
        "yc/EUR:ESTR",
        [1.0, 3.0, 6.0, 10.0],
        [1.0, 1.0, 1.0,  1.0] .* 1e-2,
    )
    yc_euribor6m = DiffFusion.linear_zero_curve(
        "yc/EUR:EURIBOR6M",
        [1.0, 3.0, 6.0, 10.0],
        [2.0, 2.0, 2.0,  2.0] .* 1e-2,
    )

    # yc_estr = DiffFusion.flat_forward("yc/EUR:ESTR", 0.01)
    # yc_euribor6m = DiffFusion.flat_forward("yc/EUR:EURIBOR6M", 0.02)
    
    ts_list = [
        yc_estr,
        yc_euribor6m,
    ]
    
    _empty_key = DiffFusion._empty_context_key
    context = DiffFusion.Context(
        "Std",
        DiffFusion.NumeraireEntry("EUR", "md/EUR", Dict(_empty_key => "yc/EUR:ESTR")),
        Dict{String, DiffFusion.RatesEntry}([
            ("EUR", DiffFusion.RatesEntry("EUR", "md/EUR", Dict(
                _empty_key  => "yc/EUR:ESTR",
                "ESTR"      => "yc/EUR:ESTR",
                "EURIBOR6M" => "yc/EUR:EURIBOR6M",
            ))),
        ]),
        Dict{String, DiffFusion.AssetEntry}(),
        Dict{String, DiffFusion.ForwardIndexEntry}(),
        Dict{String, DiffFusion.FutureIndexEntry}(),
        Dict{String, DiffFusion.FixingEntry}(),
    )
    
    path = DiffFusion.path(sim, ts_list, context, DiffFusion.LinearPathInterpolation)
    
    
    # Vanilla Swap
    
    fixed_flows = [
        DiffFusion.FixedRateCoupon( 1.0, 0.02, 1.0),
        DiffFusion.FixedRateCoupon( 2.0, 0.02, 1.0),
        DiffFusion.FixedRateCoupon( 3.0, 0.02, 1.0),
        DiffFusion.FixedRateCoupon( 4.0, 0.02, 1.0),
        DiffFusion.FixedRateCoupon( 5.0, 0.02, 1.0),
        DiffFusion.FixedRateCoupon( 6.0, 0.02, 1.0),
        DiffFusion.FixedRateCoupon( 7.0, 0.02, 1.0),
        DiffFusion.FixedRateCoupon( 8.0, 0.02, 1.0),
        DiffFusion.FixedRateCoupon( 9.0, 0.02, 1.0),
        DiffFusion.FixedRateCoupon(10.0, 0.02, 1.0),
    ];
    
    libor_flows = [
        DiffFusion.SimpleRateCoupon(0.0, 0.0, 0.5, 0.5, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(0.5, 0.5, 1.0, 1.0, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(1.0, 1.0, 1.5, 1.5, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(1.5, 1.5, 2.0, 2.0, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(2.0, 2.0, 2.5, 2.5, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(2.5, 2.5, 3.0, 3.0, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(3.0, 3.0, 3.5, 3.5, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(3.5, 3.5, 4.0, 4.0, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(4.0, 4.0, 4.5, 4.5, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(4.5, 4.5, 5.0, 5.0, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(5.0, 5.0, 5.5, 5.5, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(5.5, 5.5, 6.0, 6.0, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(6.0, 6.0, 6.5, 6.5, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(6.5, 6.5, 7.0, 7.0, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(7.0, 7.0, 7.5, 7.5, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(7.5, 7.5, 8.0, 8.0, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(8.0, 8.0, 8.5, 8.5, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(8.5, 8.5, 9.0, 9.0, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(9.0, 9.0, 9.5, 9.5, 0.5, "EUR:EURIBOR6M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(9.5, 9.5, 10.0, 10.0, 0.5, "EUR:EURIBOR6M", nothing, nothing),
    ]
    
    fixed_notionals = 10_000.00 * ones(length(fixed_flows))
    fixed_leg = DiffFusion.cashflow_leg(
        "leg/1", fixed_flows, fixed_notionals, "EUR:ESTR", nothing,  1.0,
    )
    
    libor_notionals = 10_000.00 * ones(length(libor_flows))
    libor_leg = DiffFusion.cashflow_leg(
        "leg/2", libor_flows, libor_notionals, "EUR:ESTR", nothing,  -1.0
    )
    
    vanilla_swap = [ fixed_leg, libor_leg ]
    
    
    # European Swaptions
    
    payer_receiver = -1.0  # fixed receiver swaptions; put option on swap rate
    swap_disc_curve_key = "EUR:ESTR"
    settlement_type = DiffFusion.SwaptionPhysicalSettlement
    notional = 10_000.00
    
    swpt_disc_curve_key = "EUR:ESTR"
    swpt_fx_key = nothing
    swpt_long_short = 1.0
    
    make_swaption(_alias, _expiry_time, _libor_coupons, _fixed_coupons, ) = DiffFusion.SwaptionLeg(
        _alias,
        _expiry_time,
        _expiry_time, # settlement_time
        _libor_coupons,
        _fixed_coupons,
        payer_receiver,
        swap_disc_curve_key,
        settlement_type,
        notional,
        swpt_disc_curve_key,
        swpt_fx_key,
        swpt_long_short,
    )
    
    swaption_2y = make_swaption("leg/swpn/2y", 2.0, libor_flows[5:end], fixed_flows[3:end])
    swaption_4y = make_swaption("leg/swpn/4y", 4.0, libor_flows[9:end], fixed_flows[5:end])
    swaption_6y = make_swaption("leg/swpn/6y", 6.0, libor_flows[13:end], fixed_flows[7:end])
    swaption_8y = make_swaption("leg/swpn/8y", 8.0, libor_flows[17:end], fixed_flows[9:end])
    
    
    # Bermudan Swaption
    
    make_regression_variables(t) = [ DiffFusion.LiborRate(t, t, 10.0, "EUR:EURIBOR6M"), ]
    
    swap_2y_10y = [
        DiffFusion.cashflow_leg("leg/fixed/2y-10y",fixed_flows[3:end], fixed_notionals[3:end], "EUR:ESTR", nothing,  1.0),  # receiver
        DiffFusion.cashflow_leg("leg/libor/2y-10y",libor_flows[5:end], libor_notionals[5:end], "EUR:ESTR", nothing, -1.0),  # payer
    ]
    
    swap_4y_10y = [
        DiffFusion.cashflow_leg("leg/fixed/4y-10y",fixed_flows[5:end], fixed_notionals[5:end], "EUR:ESTR", nothing,  1.0),  # receiver
        DiffFusion.cashflow_leg("leg/libor/4y-10y",libor_flows[9:end], libor_notionals[9:end], "EUR:ESTR", nothing, -1.0),  # payer
    ]
    
    swap_6y_10y = [
        DiffFusion.cashflow_leg("leg/fixed/6y-10y",fixed_flows[7:end], fixed_notionals[7:end], "EUR:ESTR", nothing,  1.0),  # receiver
        DiffFusion.cashflow_leg("leg/libor/6y-10y",libor_flows[13:end], libor_notionals[13:end], "EUR:ESTR", nothing, -1.0),  # payer
    ]
    
    swap_8y_10y = [
        DiffFusion.cashflow_leg("leg/fixed/6y-10y",fixed_flows[9:end], fixed_notionals[9:end], "EUR:ESTR", nothing,  1.0),  # receiver
        DiffFusion.cashflow_leg("leg/libor/6y-10y",libor_flows[17:end], libor_notionals[17:end], "EUR:ESTR", nothing, -1.0),  # payer
    ]
    
    exercise_2y = DiffFusion.bermudan_exercise(2.0, swap_2y_10y, make_regression_variables)
    exercise_4y = DiffFusion.bermudan_exercise(4.0, swap_4y_10y, make_regression_variables)
    exercise_6y = DiffFusion.bermudan_exercise(6.0, swap_6y_10y, make_regression_variables)
    exercise_8y = DiffFusion.bermudan_exercise(8.0, swap_8y_10y, make_regression_variables)
    
    berm_10nc2 = DiffFusion.bermudan_swaption_leg(
        "berm/10-nc-2",
        [ exercise_2y, exercise_4y, exercise_6y, exercise_8y, ],
        1.0, # long option
        "", # default discounting (curve key)
        make_regression_variables,
        nothing, # path
        nothing, # make_regression
    )
    
    berm_4y = DiffFusion.bermudan_swaption_leg(
        "berm/4y",
        [ exercise_4y, ],
        1.0, # long option
        "", # default discounting (curve key)
        make_regression_variables,
        nothing, # path
        nothing, # make_regression
    )
    
    # AMC Regression
    
    make_regression = (C, O) -> DiffFusion.polynomial_regression(C, O, 2)
    # make_regression = (C, O) -> DiffFusion.piecewise_regression(C, O, 2, [3])
    
    DiffFusion.reset_regression!(berm_10nc2, path, make_regression)
    DiffFusion.reset_regression!(berm_4y, path, make_regression)
    
    
    # Scenario Calculation
    portfolo = [
        vanilla_swap...,
        swaption_2y,
        swaption_4y,
        swaption_6y,
        swaption_8y,
        berm_10nc2,
    ]

    function print_results(v, g, ts_labels)
        println("NPV: " * string(v))
        for (l, d) in zip(ts_labels, g)
            println(l * ": " * string(d))
        end
    end

    @testset "Test Delta calculation" begin
        @info "Start Delta calculation..."
        #
        (v1, g1, ts_labels) = DiffFusion.model_price_and_deltas_vector(
            DiffFusion.discounted_cashflows(swaption_4y, 1.0),
            path,
            1.0,
            "",
            DiffFusion.ForwardDiff
        )
        print_results(v1, g1, ts_labels)
        #
        (v2, g2, ts_labels) = DiffFusion.model_price_and_deltas_vector(
            DiffFusion.discounted_cashflows(berm_4y, 1.0),
            path,
            1.0,
            "",
            DiffFusion.ForwardDiff
        )
        print_results(v2, g2, ts_labels)
        #
        (v3, g3, ts_labels) = DiffFusion.model_price_and_deltas_vector(
            DiffFusion.discounted_cashflows(berm_10nc2, 1.0),
            path,
            1.0,
            "",
            DiffFusion.ForwardDiff
        )
        print_results(v3, g3, ts_labels)
        @info "Finished Delta calculation."
        #
        @test abs(sum(g2[1:4])/sum(g1[1:4]) - 1.0) < 1.5e-2   # berm_4y EURIBOR6M Delta
        @test abs(sum(g2[5:8])/sum(g1[5:8]) - 1.0) < 7.5e-2   # berm_4y ESTR
        #
        @test abs(sum(g3[1:4])/sum(g1[1:4]) - 1.0) < 0.27   # berm_10nc2 EURIBOR6M Delta
        @test abs(sum(g3[5:8])/sum(g1[5:8]) - 1.0) < 0.28   # berm_10nc2 ESTR
    end


    @testset "Test Vega calculation" begin
        @info "Start Vega calculation..."
        #
        hyb_model = DiffFusion.simple_model("Std", [model])
        sim(model, ch) = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false, brownian_increments = DiffFusion.sobol_brownian_increments)
        #
        (v1, g1, ts_labels) = DiffFusion.model_price_and_vegas_vector(
            DiffFusion.discounted_cashflows(swaption_4y, 1.0),
            hyb_model,
            sim,
            ts_list,
            context,
            1.0,
            "",
            DiffFusion.ForwardDiff
        )
        print_results(v1, g1, ts_labels)
        #
        (v2, g2, ts_labels) = DiffFusion.model_price_and_vegas_vector(
            DiffFusion.discounted_cashflows(berm_4y, 1.0),
            hyb_model,
            sim,
            ts_list,
            context,
            1.0,
            "",
            DiffFusion.ForwardDiff
        )
        print_results(v2, g2, ts_labels)
        #
        (v3, g3, ts_labels) = DiffFusion.model_price_and_vegas_vector(
            DiffFusion.discounted_cashflows(berm_10nc2, 1.0),
            hyb_model,
            sim,
            ts_list,
            context,
            1.0,
            "",
            DiffFusion.ForwardDiff
        )
        print_results(v3, g3, ts_labels)
        @info "Finished Vega calculation."
        #
        @test abs(sum(g2)/sum(g1) - 1.0) < 1.0e-1   # berm_4y IR Vega
    end


end