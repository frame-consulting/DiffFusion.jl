
push!(LOAD_PATH,"./src/")
push!(LOAD_PATH,"../../src/")

using DiffFusion
using Plots

@info "Set up SOFR vs ESTR swap and create animated graph ..."

ex = DiffFusion.Examples.load("g3_1factor_flat")
ex = DiffFusion.Examples.build(ex)
ts = DiffFusion.Examples.term_structures(ex)

times = 0.0:1.0/48:5.0
n_paths = 2^13
sim = DiffFusion.simple_simulation(ex["md/G3"], ex["ch/STD"], times, n_paths)
path = DiffFusion.path(sim, ts, ex["ct/STD"], DiffFusion.LinearPathInterpolation)

coupon_times = 0.0:0.25:5.0
usd_coupons = [
    DiffFusion.CompoundedRateCoupon([s, e], [e-s], e, "USD:SOFR", nothing, nothing)
    for (s, e) in zip(coupon_times[1:end-1], coupon_times[2:end])
]
usd_floorlets = [
    DiffFusion.OptionletCoupon(cp, 0.0, -1.0) for cp in usd_coupons
]
usd_coupons_floored = [
    cp + fl for (cp, fl) in zip(usd_coupons, usd_floorlets)
]
eur_coupons = [
    DiffFusion.CompoundedRateCoupon([s, e], [e-s], e, "EUR:ESTR", nothing, 0.0050)
    for (s, e) in zip(coupon_times[1:end-1], coupon_times[2:end])
]

eur_leg = DiffFusion.cashflow_leg("leg/ESTR", eur_coupons, 10_000.00, "EUR:XCCY", "EUR-USD", +1.0)
#
usd_const_leg = DiffFusion.cashflow_leg("leg/SOFR/CN", usd_coupons, 10_000.00 * 1.07, "USD:SOFR", nothing, -1.0)
#
usd_mtm_leg = DiffFusion.mtm_cashflow_leg("leg/SOFR/MTM", usd_const_leg, 10_000.00, 0.0, "EUR:XCCY", "EUR-USD")

# final notional exchange are only used for ad-hoc comparison
eur_notional_leg = DiffFusion.cashflow_leg(
    "leg/EUR/NTL", 
    [ DiffFusion.FixedCashFlow(5.0, 1.0) ],
    10_000.00,
    "EUR:XCCY",
    "EUR-USD",
    -1.0,
)
usd_notional_leg = DiffFusion.cashflow_leg(
    "leg/USD/NTL", 
    [ DiffFusion.FixedCashFlow(5.0, 1.0) ],
    10_000.00 * 1.07,
    "USD:SOFR",
    nothing,
    +1.0,
)

swap = [eur_leg, usd_mtm_leg]
# swap = [usd_const_floor_leg]
# swap = [eur_leg, usd_mtm_leg, usd_mtm_floor_leg]
# swap = [eur_leg, usd_const_leg, eur_notional_leg, usd_notional_leg]
# swap = [eur_leg, usd_const_leg]
# swap = [eur_notional_leg, usd_notional_leg]

scens1 = DiffFusion.scenarios(swap, times, path, nothing)

scens2 = DiffFusion.collateralised_portfolio(
    scens1,
    nothing,
    times,
    0.0, # initial_collateral_balance
    0.0, # minimum_transfer_amount
    0.0, # threshold_amount
    0.0, # independent_amount
    2/48.0, # mpr
)


"""
Create an animated plot that compares analytics for two input scenarios
"""
function compare_scenarios(
    scens1::DiffFusion.ScenarioCube,
    scens2::DiffFusion.ScenarioCube;
    plot_title::String = "Scenario Analysis",
    sub_plot_title1::String = "first portfolio",
    sub_plot_title2::String = "second portfolio",
    xlabel::String = "observation time (years)",
    ylabel::String = "market value",
    xlims::Tuple = (0.0, 10.0),
    ylims::Tuple = (-10_000., +10_000.),
    font_size::Integer = 10,
    plot_size::Tuple = (600, 800),
    first_paths::Integer = 8,
    second_paths::Integer = 128,
    wait_seconds::Integer = 4,
    pfe_quantile = 0.95,
    line_width = 2,
    )
    #
    @info "Calculate analytics for first scenarios."
    scens1_agg = DiffFusion.aggregate(scens1, false, true)
    scens1_mv = DiffFusion.aggregate(scens1, true, true)
    scens1_ee = DiffFusion.expected_exposure(scens1, false, true, true)
    scens1_pfe = DiffFusion.potential_future_exposure(scens1, pfe_quantile)
    #
    @info "Calculate analytics for second scenarios."
    scens2_agg = DiffFusion.aggregate(scens2, false, true)
    scens2_mv = DiffFusion.aggregate(scens2, true, true)
    scens2_ee = DiffFusion.expected_exposure(scens2, false, true, true)
    scens2_pfe = DiffFusion.potential_future_exposure(scens2, 0.95)
    #
    a = Animation()
    #
    # we define some auxilliary functions...    
    #
    function wait(n_seconds, p)
        for i ∈ 1:n_seconds
            frame(a, p)
        end    
    end
    #
    function super_plot(p1, p2)
        return  plot(p1, p2,
            layout = (2,1),
            size = plot_size,
            plot_title = plot_title,
            plot_titlefontsize = font_size,
            left_margin = 5Plots.mm  # adjust this if xaxis label is cut off
        )
    end
    #
    function plot_paths(with_frame)
        p1 = plot(
            title = sub_plot_title1,
            titlefontsize = font_size,
            titlelocation = :right,
            guidefontsize = font_size,
            color_palette = :tab10
        )
        ylabel!(p1, ylabel)
        ylims!(p1, ylims...)
        #
        p2 = plot(
            title = sub_plot_title2,
            titlefontsize = font_size,
            titlelocation = :right,
            guidefontsize = font_size,
            color_palette = :tab10
        )
        xlabel!(p2, xlabel)
        ylabel!(p2, ylabel)
        ylims!(p2, ylims...)
        for i ∈ 1:first_paths
            plot!(p1, scens1_agg.times, scens1_agg.X[i,:,1], label="", lc=8)
            plot!(p2, scens2_agg.times, scens2_agg.X[i,:,1], label="", lc=8)
            p = super_plot(p1, p2)
            if with_frame
                frame(a, p)
            end
        end
        plot!(p1, scens1_agg.times, scens1_agg.X[first_paths+1:second_paths,:,1]', label="", lc=8)
        plot!(p2, scens2_agg.times, scens2_agg.X[first_paths+1:second_paths,:,1]', label="", lc=8)
        p = super_plot(p1, p2)
        if with_frame
            wait(wait_seconds, p)
        end
        return (p, p1, p2)
    end
    #
    @info "Build animation."
    # Full graph as first frame for PDF
    (p, p1, p2) = plot_paths(false)
    plot!(p1, scens1_pfe.times, scens1_pfe.X[1,:,1], label="potential future exposure",    lc=4, lw=line_width)
    plot!(p2, scens2_pfe.times, scens2_pfe.X[1,:,1], label="potential future exposure",    lc=4, lw=line_width)
    plot!(p1, scens1_ee.times,  scens1_ee.X[1,:,1],  label="expected (positive) exposure", lc=2, lw=line_width)
    plot!(p2, scens2_ee.times,  scens2_ee.X[1,:,1],  label="expected (positive) exposure", lc=2, lw=line_width)
    plot!(p1, scens1_mv.times,  scens1_mv.X[1,:,1],  label="expected market value",        lc=3, lw=line_width)
    plot!(p2, scens2_mv.times,  scens2_mv.X[1,:,1],  label="expected market value",        lc=3, lw=line_width)
    p = super_plot(p1, p2)
    wait(1, p)
    # intitial frames
    plot_paths(true)
    # expected market value
    (p, p1, p2) = plot_paths(false)
    plot!(p1, scens1_mv.times, scens1_mv.X[1,:,1], label="expected market value", lc=3, lw=line_width)
    plot!(p2, scens2_mv.times, scens2_mv.X[1,:,1], label="expected market value", lc=3, lw=line_width)
    p = super_plot(p1, p2)
    wait(4, p)
    # expected exposure
    (p, p1, p2) = plot_paths(false)
    plot!(p1, scens1_ee.times, scens1_ee.X[1,:,1], label="expected (positive) exposure", lc=2, lw=line_width)
    plot!(p2, scens2_ee.times, scens2_ee.X[1,:,1], label="expected (positive) exposure", lc=2, lw=line_width)
    plot!(p1, scens1_mv.times, scens1_mv.X[1,:,1], label="expected market value",        lc=3, lw=line_width)
    plot!(p2, scens2_mv.times, scens2_mv.X[1,:,1], label="expected market value",        lc=3, lw=line_width)
    p = super_plot(p1, p2)
    wait(4, p)
    # PFE
    (p, p1, p2) = plot_paths(false)
    plot!(p1, scens1_pfe.times, scens1_pfe.X[1,:,1], label="potential future exposure",    lc=4, lw=line_width)
    plot!(p2, scens2_pfe.times, scens2_pfe.X[1,:,1], label="potential future exposure",    lc=4, lw=line_width)
    plot!(p1, scens1_ee.times,  scens1_ee.X[1,:,1],  label="expected (positive) exposure", lc=2, lw=line_width)
    plot!(p2, scens2_ee.times,  scens2_ee.X[1,:,1],  label="expected (positive) exposure", lc=2, lw=line_width)
    plot!(p1, scens1_mv.times,  scens1_mv.X[1,:,1],  label="expected market value",        lc=3, lw=line_width)
    plot!(p2, scens2_mv.times,  scens2_mv.X[1,:,1],  label="expected market value",        lc=3, lw=line_width)
    p = super_plot(p1, p2)
    wait(10, p)
    @info "Plot GIF."
    gif(a, fps = 1)
    # display(p)
end


# calculate animation and plot graph
compare_scenarios(
    scens1,
    scens2,
    plot_title = "(Floored) SOFR vs ESTR mark-to-market cross currency swap",
    sub_plot_title1 = "no collateral",
    sub_plot_title2 = "full collateral, two weeks MPoR",
    ylabel = "market value (USD, bp)",
    ylims = (-4000., 4000),
)
