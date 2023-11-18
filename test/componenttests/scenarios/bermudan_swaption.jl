using DiffFusion
using Serialization
using Test

@testset "Test Bermudan swaption simulation" begin

    # simple rate as single regression payoff
    make_regression_variables(t) = [ DiffFusion.LiborRate(t, t, 5.0, "EUR:EURIBOR12M"), ]

    fixed_flows = [
        DiffFusion.FixedRateCoupon(2.0, 0.03, 1.0),
        DiffFusion.FixedRateCoupon(3.0, 0.03, 1.0),
        DiffFusion.FixedRateCoupon(4.0, 0.03, 1.0),
        DiffFusion.FixedRateCoupon(5.0, 0.03, 1.0),
        ]

    libor_flows = [
        DiffFusion.SimpleRateCoupon(1.0, 1.0, 2.0, 2.0, 1.0, "EUR:EURIBOR12M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(2.0, 2.0, 3.0, 3.0, 1.0, "EUR:EURIBOR12M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(3.0, 3.0, 4.0, 4.0, 1.0, "EUR:EURIBOR12M", nothing, nothing),
        DiffFusion.SimpleRateCoupon(4.0, 4.0, 5.0, 5.0, 1.0, "EUR:EURIBOR12M", nothing, nothing),
    ]

    notionals = [ 1.0, 1.0, 1.0, 1.0, ]

    exercise_1 = DiffFusion.bermudan_exercise(
        1.0,
        [
            DiffFusion.cashflow_leg("leg_1",fixed_flows[1:end], notionals[1:end], "EUR:ESTR", nothing,  1.0),  # receiver
            DiffFusion.cashflow_leg("leg_2",libor_flows[1:end], notionals[1:end], "EUR:ESTR", nothing, -1.0),  # payer
        ],
        make_regression_variables,
    )
    exercise_2 = DiffFusion.bermudan_exercise(
        2.0,
        [
            DiffFusion.cashflow_leg("leg_1",fixed_flows[2:end], notionals[2:end], "EUR:ESTR", nothing,  1.0),  # receiver
            DiffFusion.cashflow_leg("leg_2",libor_flows[2:end], notionals[2:end], "EUR:ESTR", nothing, -1.0),  # payer
        ],
        make_regression_variables,
    )
    exercise_3 = DiffFusion.bermudan_exercise(
        3.0,
        [
            DiffFusion.cashflow_leg("leg_1",fixed_flows[3:end], notionals[3:end], "EUR:ESTR", nothing,  1.0),  # receiver
            DiffFusion.cashflow_leg("leg_2",libor_flows[3:end], notionals[3:end], "EUR:ESTR", nothing, -1.0),  # payer
        ],
        make_regression_variables,
    )

    @testset "Test simulation." begin
        berm = DiffFusion.bermudan_swaption_leg(
            "berm",
            [ exercise_1, exercise_2, exercise_3,],
            1.0, # long option
            "", # default discounting (curve key)
            make_regression_variables,
            nothing, # path
            nothing, # make_regression
        )
        @test isa(berm, DiffFusion.BermudanSwaptionLeg)
        #
        ch_one = DiffFusion.correlation_holder("One")
        delta_eur = DiffFusion.flat_parameter([ 0., ])
        chi_eur = DiffFusion.flat_parameter([ 0.01, ])
        sigma_f_eur = DiffFusion.flat_volatility("EUR", 0.01)
        hjm_model_eur = DiffFusion.gaussian_hjm_model("mdl/EUR", delta_eur, chi_eur, sigma_f_eur, ch_one, nothing)
        #
        _empty_key = DiffFusion._empty_context_key
        context = DiffFusion.Context(
            "Std",
            DiffFusion.NumeraireEntry("EUR", "mdl/EUR", Dict(_empty_key => "yc/EUR:ESTR")),
            Dict{String, DiffFusion.RatesEntry}([
                ("EUR", DiffFusion.RatesEntry("EUR", "mdl/EUR", Dict(
                    _empty_key => "yc/EUR:ESTR",
                    "ESTR"      => "yc/EUR:ESTR",
                    "EURIBOR12M" => "yc/EUR:EURIBOR12M",
                ))),
            ]),
            Dict{String, DiffFusion.AssetEntry}(),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}(),
        )
        #
        ts_list = [
            DiffFusion.flat_forward("yc/EUR:ESTR", 0.02),
            DiffFusion.flat_forward("yc/EUR:EURIBOR12M", 0.025),
        ]
        #
        times = 0.0:0.1:5.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(hjm_model_eur, ch_one, times, n_paths, with_progress_bar = true)
        path = DiffFusion.path(sim, ts_list, context, DiffFusion.LinearPathInterpolation)
        #
        make_regression = (C, O) -> DiffFusion.polynomial_regression(C, O, 3)
        # make_regression = (C, O) -> DiffFusion.piecewise_regression(C, O, 2, [3,])

        DiffFusion.reset_regression!(berm, path, make_regression)
        #
        scens = DiffFusion.scenarios([berm], times, path, "")
        println(size(scens.X))
        println(size(sim.X))
        #
        # X = sim.X[1,:,:]
        # B = scens.X[:,:,1]
        # println(size(B))
        # serialize(".sandbox/T.data", times)
        # serialize(".sandbox/X.data", X)
        # serialize(".sandbox/B.data", B)
    end

end