
using DiffFusion
using Test
using UnicodePlots

@testset "Test rates option simulation" begin
    
    ch_full = DiffFusion.correlation_holder("Full")
    DiffFusion.set_correlation!(ch_full, "EUR_f_1", "EUR_f_2", 0.8)
    DiffFusion.set_correlation!(ch_full, "EUR_f_2", "EUR_f_3", 0.8)
    DiffFusion.set_correlation!(ch_full, "EUR_f_1", "EUR_f_3", 0.5)
    #
    delta_dom = DiffFusion.flat_parameter([ 1., 7., 15. ])
    chi_dom = DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ])
    times_dom =  [ 0. ]
    values_dom = [ 100. 100. 100. ]' * 1.0e-4
    sigma_f_dom = DiffFusion.backward_flat_volatility("sigma/EUR", times_dom, values_dom)
    hjm_model_dom = DiffFusion.gaussian_hjm_model("mdl/EUR", delta_dom, chi_dom, sigma_f_dom, ch_full, nothing)
    #
    ctx = DiffFusion.context(
        "Std",
        DiffFusion.numeraire_entry("EUR", "mdl/EUR", "yc/EUR/OIS"),
        [
            DiffFusion.rates_entry("EUR", "mdl/EUR", Dict("OIS" => "yc/EUR/OIS", "E6M" => "yc/EUR/E6M")),
        ],
    )
    ts = [
        DiffFusion.flat_forward("yc/EUR/OIS", 0.01)
        DiffFusion.flat_forward("yc/EUR/E6M", 0.02)
    ]
    #
    times = 0.0:1.0/48:2.0
    n_paths = 2^10
    sim = DiffFusion.simple_simulation(hjm_model_dom, ch_full, times, n_paths, with_progress_bar = true)
    path = DiffFusion.path(sim, ts, ctx, DiffFusion.LinearPathInterpolation)

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

    @testset "Libor option simulation" begin
        float_coupons = [
            DiffFusion.SimpleRateCoupon(0.0, 0.0, 0.5, 0.5, 0.5, "EUR:E6M", nothing, nothing)
            DiffFusion.SimpleRateCoupon(0.5, 0.5, 1.0, 1.0, 0.5, "EUR:E6M", nothing, nothing)
            DiffFusion.SimpleRateCoupon(1.0, 1.0, 1.5, 1.5, 0.5, "EUR:E6M", nothing, nothing)
            DiffFusion.SimpleRateCoupon(1.5, 1.5, 2.0, 2.0, 0.5, "EUR:E6M", nothing, nothing)
        ]
        capl_coupons = [
            DiffFusion.OptionletCoupon(cf, 0.01, +1.0)
            for cf in float_coupons
        ]
        floor_coupons = [
            DiffFusion.OptionletCoupon(cf, 0.02, -1.0)
            for cf in float_coupons
        ]
        leg1 = DiffFusion.cashflow_leg("lib/E6M", float_coupons, 100.0, "EUR:OIS")
        leg2 = DiffFusion.cashflow_leg("lib/CPL", capl_coupons, 100.0, "EUR:OIS")
        leg3 = DiffFusion.cashflow_leg("lib/FLR", floor_coupons, 100.0, "EUR:OIS")
        scens = DiffFusion.scenarios([leg1, leg2, leg3], times, path, nothing)
        mv = DiffFusion.aggregate(scens, true, false)
        plot_scens(mv, "market value - Libor options")
    end


    @testset "OIS option simulation" begin
        float_coupons = [
            DiffFusion.CompoundedRateCoupon([0.0, 0.5], [0.5], 0.5, "EUR:E6M", nothing, nothing)
            DiffFusion.CompoundedRateCoupon([0.5, 1.0], [0.5], 1.0, "EUR:E6M", nothing, nothing)
            DiffFusion.CompoundedRateCoupon([1.0, 1.5], [0.5], 1.5, "EUR:E6M", nothing, nothing)
            DiffFusion.CompoundedRateCoupon([1.5, 2.0], [0.5], 2.0, "EUR:E6M", nothing, nothing)
        ]
        capl_coupons = [
            DiffFusion.OptionletCoupon(cf, 0.01, +1.0)
            for cf in float_coupons
        ]
        floor_coupons = [
            DiffFusion.OptionletCoupon(cf, 0.02, -1.0)
            for cf in float_coupons
        ]
        leg1 = DiffFusion.cashflow_leg("ois/E6M", float_coupons, 100.0, "EUR:OIS")
        leg2 = DiffFusion.cashflow_leg("ois/CPL", capl_coupons, 100.0, "EUR:OIS")
        leg3 = DiffFusion.cashflow_leg("ois/FLR", floor_coupons, 100.0, "EUR:OIS")
        scens = DiffFusion.scenarios([leg1, leg2, leg3 ], times, path, nothing)
        mv = DiffFusion.aggregate(scens, true, false)
        plot_scens(mv, "market value - OIS options")
    end

    @testset "Libor versus OIS option simulation" begin
        lib_float_coupons = [
            DiffFusion.SimpleRateCoupon(0.0, 0.0, 0.5, 0.5, 0.5, "EUR:E6M", nothing, nothing)
            DiffFusion.SimpleRateCoupon(0.5, 0.5, 1.0, 1.0, 0.5, "EUR:E6M", nothing, nothing)
            DiffFusion.SimpleRateCoupon(1.0, 1.0, 1.5, 1.5, 0.5, "EUR:E6M", nothing, nothing)
            DiffFusion.SimpleRateCoupon(1.5, 1.5, 2.0, 2.0, 0.5, "EUR:E6M", nothing, nothing)
        ]
        lib_capl_coupons = [
            DiffFusion.OptionletCoupon(cf, 0.01, +1.0)
            for cf in lib_float_coupons
        ]
        lib_floor_coupons = [
            DiffFusion.OptionletCoupon(cf, 0.02, -1.0)
            for cf in lib_float_coupons
        ]
        lib_leg1 = DiffFusion.cashflow_leg("lib/E6M", lib_float_coupons, 100.0, "EUR:OIS", nothing, -1.0)
        lib_leg2 = DiffFusion.cashflow_leg("lib/CPL", lib_capl_coupons, 100.0, "EUR:OIS", nothing, -1.0)
        lib_leg3 = DiffFusion.cashflow_leg("lib/FLR", lib_floor_coupons, 100.0, "EUR:OIS", nothing, -1.0)
        #
        ois_float_coupons = [
            DiffFusion.CompoundedRateCoupon([0.0, 0.5], [0.5], 0.5, "EUR:E6M", nothing, nothing)
            DiffFusion.CompoundedRateCoupon([0.5, 1.0], [0.5], 1.0, "EUR:E6M", nothing, nothing)
            DiffFusion.CompoundedRateCoupon([1.0, 1.5], [0.5], 1.5, "EUR:E6M", nothing, nothing)
            DiffFusion.CompoundedRateCoupon([1.5, 2.0], [0.5], 2.0, "EUR:E6M", nothing, nothing)
        ]
        ois_capl_coupons = [
            DiffFusion.OptionletCoupon(cf, 0.01, +1.0)
            for cf in ois_float_coupons
        ]
        ois_floor_coupons = [
            DiffFusion.OptionletCoupon(cf, 0.02, -1.0)
            for cf in ois_float_coupons
        ]
        ois_leg1 = DiffFusion.cashflow_leg("ois/E6M", ois_float_coupons, 100.0, "EUR:OIS")
        ois_leg2 = DiffFusion.cashflow_leg("ois/CPL", ois_capl_coupons, 100.0, "EUR:OIS")
        ois_leg3 = DiffFusion.cashflow_leg("ois/FLR", ois_floor_coupons, 100.0, "EUR:OIS")
        #
        scens1 = DiffFusion.scenarios([lib_leg1, ois_leg1 ], times, path, nothing)
        scens2 = DiffFusion.scenarios([lib_leg2, ois_leg2 ], times, path, nothing)
        scens3 = DiffFusion.scenarios([lib_leg3, ois_leg3 ], times, path, nothing)
        mv1 = DiffFusion.aggregate(scens1)
        mv2 = DiffFusion.aggregate(scens2)
        mv3 = DiffFusion.aggregate(scens3)
        plot_scens(mv1, "market value - OIS vs Libor options")
        plot_scens(mv2, "market value - OIS vs Libor options")
        plot_scens(mv3, "market value - OIS vs Libor options")
    end

    times = 0.0:1.0/12:10.0
    n_paths = 2^10
    sim = DiffFusion.simple_simulation(hjm_model_dom, ch_full, times, n_paths, with_progress_bar = true)
    path = DiffFusion.path(sim, ts, ctx, DiffFusion.LinearPathInterpolation)

    @testset "Libor swaption simulation" begin
        start_time = 5.0
        end_time = 10.0
        float_times = start_time:0.5:end_time
        lib_float_coupons = [
            DiffFusion.SimpleRateCoupon(s, s, e, e, e-s, "EUR:E6M", nothing, nothing)
            for (s, e) in zip(float_times[1:end-1], float_times[2:end])
        ]
        fixed_rate = 0.02
        fixed_times = start_time:1.0:end_time
        fixed_coupons = [
            DiffFusion.FixedRateCoupon(e, fixed_rate, e-s)
            for (s, e) in zip(fixed_times[1:end-1], fixed_times[2:end])
        ]
        lib_leg = DiffFusion.SwaptionLeg("lib/5x10", start_time, start_time, lib_float_coupons, fixed_coupons, 1.0, "EUR:OIS", DiffFusion.SwaptionPhysicalSettlement, 100.0)
        scens = DiffFusion.scenarios([lib_leg, ], times, path, "EUR")
        mv = DiffFusion.aggregate(scens)
        ee = DiffFusion.expected_exposure(scens)
        plot_scens(mv, "market value - Libor swaption")
        plot_scens(ee, "EE - Libor swaption")
    end

    @testset "OIS swaption simulation" begin
        start_time = 5.0
        end_time = 10.0
        float_times = start_time:0.5:end_time
        lib_float_coupons = [
            DiffFusion.CompoundedRateCoupon([s, e], [e-s], e, "EUR:E6M", nothing, nothing)
            for (s, e) in zip(float_times[1:end-1], float_times[2:end])
        ]
        fixed_rate = 0.02
        fixed_times = start_time:1.0:end_time
        fixed_coupons = [
            DiffFusion.FixedRateCoupon(e, fixed_rate, e-s)
            for (s, e) in zip(fixed_times[1:end-1], fixed_times[2:end])
        ]
        lib_leg = DiffFusion.SwaptionLeg("ois/5x10", start_time, start_time, lib_float_coupons, fixed_coupons, 1.0, "EUR:OIS", DiffFusion.SwaptionPhysicalSettlement, 100.0)
        scens = DiffFusion.scenarios([lib_leg, ], times, path, "EUR")
        mv = DiffFusion.aggregate(scens)
        ee = DiffFusion.expected_exposure(scens)
        plot_scens(mv, "market value - OIS swaption")
        plot_scens(ee, "EE - OIS swaption")
    end

end

