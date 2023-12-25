
using DiffFusion
using Test
using UnicodePlots

@testset "Test collateral simulation" begin
    
    if !@isdefined(TestModels)
        include("../../test_models.jl")
    end

    model = TestModels.hybrid_model_full
    ch = TestModels.ch_full
    times = 0.0:1.0/12:5.0
    n_paths = 2^3
    sim = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = true)
    path = DiffFusion.path(sim, TestModels.ts_list, TestModels.context, DiffFusion.LinearPathInterpolation)

    float_times = 0.0:0.5:5.0
    float_coupons = [
        DiffFusion.SimpleRateCoupon(s, s, e, e, e-s, "EUR", nothing, nothing)
        for (s, e) in zip(float_times[1:end-1], float_times[2:end])
    ]
    float_times = 0.0:1.0:5.0
    fixed_couons = [
        DiffFusion.FixedRateCoupon(e, 0.02, e-s)
        for (s, e) in zip(float_times[1:end-1], float_times[2:end])
    ]
    notional = 100.0
    disc_curve_key = "EUR:XCY"
    fx_key = "EUR-USD"
    payer_receiver = 1.0  # fixed
    leg1 = DiffFusion.cashflow_leg("leg/6m", float_coupons, notional, disc_curve_key, fx_key,  payer_receiver)
    leg2 = DiffFusion.cashflow_leg("leg/2%", fixed_couons,  notional, disc_curve_key, fx_key, -payer_receiver)

    fx_leg = DiffFusion.cash_balance_leg("leg/EUR-USD", 1.0, "EUR-USD")

    function plot_scens(scens, title)
        plt = lineplot(scens.times, scens.X[1,:,:],
            title = title,
            name = scens.leg_aliases,
            xlabel = "obs_time",
            ylabel = "price (EUR)",
            width = 80,
            height = 30,
        )
        println()
        display(plt)
        println()
    end

    times = 0.0:1.0/12:5.0
    scens_legs = DiffFusion.scenarios([leg1, leg2 ], times, path, nothing)
    scens_fx = DiffFusion.scenarios([ fx_leg ], times, path, nothing)


    scens_mean = DiffFusion.aggregate(scens_legs, true, false)
    # scens_ee = DiffFusion.expected_exposure(scens_legs)
    # plot_scens(scens_mean, "EUR swap")
    # plot_scens(scens_ee, "EUR swap EE")
    # plot_scens(DiffFusion.aggregate(scens_fx), "EUR-USD")


    @testset "Test collateral balance calculation." begin
        margin_times = DiffFusion.collateral_call_times(0.5, 0.25, 5.0)
        @test margin_times == [0.0, 0.25, 0.75, 1.25, 1.75, 2.25, 2.75, 3.25, 3.75, 4.25, 4.75]
        #
        cube_csa = DiffFusion.market_values_for_csa(scens_legs, margin_times, scens_fx)
        @test cube_csa.times == margin_times
        @test size(cube_csa.X) == (8, 11, 1)
        @test cube_csa.leg_aliases == ["(leg/6m_leg/2% / leg/EUR-USD)"]
        #
        initial_collateral_balance = 3.0
        minimum_transfer_amount = 0.5
        threshold_amount = 0.1
        independent_amount = 0.0
        collateral = DiffFusion.collateral_values_for_csa(
            cube_csa,
            initial_collateral_balance,
            minimum_transfer_amount,
            threshold_amount,
            independent_amount,
        )
        @test collateral.times == margin_times
        @test size(collateral.X) == (8, 11, 1)
        @test collateral.leg_aliases == ["CB[(leg/6m_leg/2% / leg/EUR-USD)]"]
        # println(collateral.times)
        # println(size(collateral.X))
        # println(collateral.leg_aliases)
        # display(collateral.X[:,:,1])
        #
        margin_period_of_risk = 1.0/24
        scens_coll = DiffFusion.effective_collateral_values(scens_legs.times, collateral, margin_period_of_risk)
        scens = DiffFusion.join_scenarios(scens_legs/scens_fx, scens_coll)
        # plot_scens(DiffFusion.aggregate(scens_legs/scens_fx, true, true), "Coll")
        # plot_scens(DiffFusion.aggregate(scens, true, true), "Coll")
        @test scens_coll.times == scens_legs.times
        @test size(scens_coll.X) == size(scens_fx.X)
        @test collateral.leg_aliases == collateral.leg_aliases
        #
        coll_portfolio = DiffFusion.collateralised_portfolio(
            scens_legs,
            scens_fx,
            margin_times,
            initial_collateral_balance,
            minimum_transfer_amount,
            threshold_amount,
            independent_amount,
            margin_period_of_risk,
        )
        #
        @test isapprox(coll_portfolio.X, (scens * scens_fx).X, atol=1.0e-12)
    end

end
