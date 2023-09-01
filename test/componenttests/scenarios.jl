
using Base.Threads
using DiffFusion
using OrderedCollections
using Printf
using Random
using Test
using UnicodePlots
using YAML

@testset "Scenario generation." begin

    yaml_string =
    """
    config/instruments:
      seed: 123456
      types:
        - USD
        - EUR
        - GBP
        - EUR-USD
        - GBP-USD
        - EUR6M-USD3M
      USD:
        type: VANILLA
        discount_curve_key: USD:SOFR
        fx_key:
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        fixed_leg:
          coupons_per_year: 4
          min_rate: 0.01
          max_rate: 0.04
        float_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: USD:SOFR
          fixing_key: USD:SOFR
      EUR:
        type: VANILLA
        discount_curve_key: EUR:XCCY
        fx_key: EUR-USD
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        fixed_leg:
          coupons_per_year: 1
          min_rate: 0.01
          max_rate: 0.04
        float_leg:
          coupon_type: SIMPLE
          coupons_per_year: 2
          forward_curve_key: EUR:EURIBOR6M
          fixing_key: EUR:EURIBOR6M
      GBP:
        type: VANILLA
        discount_curve_key: GBP:XCCY
        fx_key: GBP-USD
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        fixed_leg:
          coupons_per_year: 4
          min_rate: 0.01
          max_rate: 0.04
        float_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: GBP:SONIA
          fixing_key: GBP:SONIA
      EUR-USD:
        type: BASIS-MTM
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        dom_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: USD:SOFR
          fixing_key: USD:SOFR
          #
          discount_curve_key: USD:SOFR
          fx_key:
        for_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: EUR:ESTR
          fixing_key: EUR:ESTR
          min_spread: 0.01
          max_spread: 0.03
          #
          discount_curve_key: EUR:XCCY
          fx_key: EUR-USD
      GBP-USD:
        type: BASIS-MTM
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        dom_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: USD:SOFR
          fixing_key: USD:SOFR
          #
          discount_curve_key: USD:SOFR
          fx_key:
        for_leg:
          coupon_type: COMPOUNDED
          coupons_per_year: 4
          forward_curve_key: GBP:SONIA
          fixing_key: GBP:SONIA
          min_spread: 0.01
          max_spread: 0.03
          #
          discount_curve_key: GBP:XCCY
          fx_key: GBP-USD
      EUR6M-USD3M:
        type: BASIS-MTM
        min_maturity: 1.0
        max_maturity: 10.0
        min_notional: 1.0e+7
        max_notional: 1.0e+8
        dom_leg:
          coupon_type: SIMPLE
          coupons_per_year: 4
          forward_curve_key: USD:LIB3M
          fixing_key: USD:LIB3M
          #
          discount_curve_key: USD:SOFR
          fx_key:
        for_leg:
          coupon_type: SIMPLE
          coupons_per_year: 2
          forward_curve_key: EUR:EURIBOR6M
          fixing_key: EUR:EURIBOR6M
          min_spread: 0.01
          max_spread: 0.03
          #
          discount_curve_key: EUR:XCCY
          fx_key: EUR-USD
    """
    
    
    ch_one = DiffFusion.correlation_holder("One")
    ch_full = DiffFusion.correlation_holder("Full")
    #
    DiffFusion.set_correlation!(ch_full, "USD_f_1", "USD_f_2", 0.8)
    DiffFusion.set_correlation!(ch_full, "USD_f_2", "USD_f_3", 0.8)
    DiffFusion.set_correlation!(ch_full, "USD_f_1", "USD_f_3", 0.5)
    #
    DiffFusion.set_correlation!(ch_full, "EUR_f_1", "EUR_f_2", 0.50)
    #
    DiffFusion.set_correlation!(ch_full, "GBP_f_1", "GBP_f_2", 0.50)
    #
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_1", -0.30)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_2", -0.30)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_3", -0.30)
    #
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_1", -0.20)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_2", -0.20)
    #
    DiffFusion.set_correlation!(ch_full, "GBP-USD_x", "GBP_f_1", 0.20)
    DiffFusion.set_correlation!(ch_full, "GBP-USD_x", "GBP_f_2", 0.20)
    #
    DiffFusion.set_correlation!(ch_full, "USD_f_1", "EUR_f_1", 0.10)
    DiffFusion.set_correlation!(ch_full, "USD_f_2", "EUR_f_2", 0.10)
    #
    DiffFusion.set_correlation!(ch_full, "USD_f_1", "GBP_f_1", 0.10)
    DiffFusion.set_correlation!(ch_full, "USD_f_2", "GBP_f_2", 0.10)
    #
    
    setup_models(ch) = begin
        sigma_fx = DiffFusion.flat_volatility("EUR-USD", 0.15)
        fx_model_EUR = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)
    
        sigma_fx = DiffFusion.flat_volatility("GBP-USD", 0.15)
        fx_model_GBP = DiffFusion.lognormal_asset_model("GBP-USD", sigma_fx, ch, nothing)
    
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
        hjm_model_EUR = DiffFusion.gaussian_hjm_model("EUR",delta_for,chi_for,sigma_f_for,ch,fx_model_EUR)
    
        delta_for = DiffFusion.flat_parameter([ 1., 10. ])
        chi_for = DiffFusion.flat_parameter([ 0.01, 0.15 ])
        times_for =  [ 0. ]
        values_for = [ 80. 90. ]' * 1.0e-4
        sigma_f_for = DiffFusion.backward_flat_volatility("GBP",times_for,values_for)
        hjm_model_GBP = DiffFusion.gaussian_hjm_model("GBP",delta_for,chi_for,sigma_f_for,ch,fx_model_GBP)
    
        return [ hjm_model_dom, fx_model_EUR, hjm_model_EUR, fx_model_GBP, hjm_model_GBP, ]
    end
    
    empty_key = DiffFusion._empty_context_key
    #
    context = DiffFusion.Context("Std",
        DiffFusion.NumeraireEntry("USD", "USD", Dict(empty_key => "yc/USD:SOFR")),
        Dict{String, DiffFusion.RatesEntry}([
            ("USD", DiffFusion.RatesEntry("USD", "USD",
                Dict(
                    empty_key => "yc/USD:SOFR",
                    "SOFR" => "yc/USD:SOFR",
                    "LIB3M" => "yc/USD:LIB3M",
                ))),
            ("EUR", DiffFusion.RatesEntry("EUR","EUR",
                Dict(
                    empty_key => "yc/EUR:XCCY",
                    "XCCY" => "yc/EUR:XCCY",
                    "ESTR" => "yc/EUR:ESTR",
                    "EURIBOR6M" => "yc/EUR:EURIBOR6M",
                ))),
            ("GBP", DiffFusion.RatesEntry("GBP","GBP",
                Dict(
                    empty_key => "yc/GBP:XCCY",
                    "XCCY" => "yc/GBP:XCCY",
                    "SONIA" => "yc/GBP:SONIA",
                ))),
        ]),
        Dict{String, DiffFusion.AssetEntry}([
            ("EUR-USD", DiffFusion.AssetEntry("EUR-USD", "EUR-USD", "USD", "EUR", "pa/EUR-USD", Dict(empty_key => "yc/USD:SOFR"), Dict(empty_key => "yc/EUR:XCCY"))), 
            ("GBP-USD", DiffFusion.AssetEntry("GBP-USD", "GBP-USD", "USD", "GBP", "pa/GBP-USD", Dict(empty_key => "yc/USD:SOFR"), Dict(empty_key => "yc/GBP:XCCY"))), 
        ]),
        Dict{String, DiffFusion.ForwardIndexEntry}(),
        Dict{String, DiffFusion.FutureIndexEntry}(),
        Dict{String, DiffFusion.FixingEntry}([
            ("USD:SOFR", DiffFusion.FixingEntry("USD:SOFR", "pa/USD:SOFR")),
            ("USD:LIB3M", DiffFusion.FixingEntry("USD:LIB3M", "pa/USD:LIB3M")),
            ("EUR:ESTR", DiffFusion.FixingEntry("EUR:ESTR", "pa/EUR:ESTR")),
            ("EUR:EURIBOR6M", DiffFusion.FixingEntry("EUR:EURIBOR6M", "pa/EUR:EURIBOR6M")),
            ("GBP:SONIA", DiffFusion.FixingEntry("GBP:SONIA", "pa/GBP:SONIA")),
        ]),
    )
    
    # term structures
    ts_list = [
        DiffFusion.flat_forward("yc/USD:SOFR", 0.03),
        DiffFusion.flat_forward("yc/USD:LIB3M", 0.035),
        DiffFusion.flat_forward("yc/EUR:XCCY", 0.025),
        DiffFusion.flat_forward("yc/EUR:ESTR", 0.02),
        DiffFusion.flat_forward("yc/EUR:EURIBOR6M", 0.025),
        DiffFusion.flat_forward("yc/GBP:XCCY", 0.02),
        DiffFusion.flat_forward("yc/GBP:SONIA", 0.02),
        #
        DiffFusion.flat_parameter("pa/EUR-USD", 1.10),
        DiffFusion.flat_parameter("pa/GBP-USD", 1.25),
        #
        DiffFusion.flat_parameter("pa/USD:SOFR", 0.03),
        DiffFusion.flat_parameter("pa/USD:LIB3M", 0.035),
        DiffFusion.flat_parameter("pa/EUR:ESTR", 0.02),
        DiffFusion.flat_parameter("pa/EUR:EURIBOR6M", 0.025),
        DiffFusion.flat_parameter("pa/GBP:SONIA", 0.02),
    ]

    function plot_swap(scens, title = "Swap")
        scens_agg = DiffFusion.aggregate(scens, true, true)
        scens_ee = DiffFusion.expected_exposure(scens)
        data = hcat(scens_agg.X[1,:,1], scens_ee.X[1,:,1])
        plt = lineplot(scens_agg.times, data,
            title = title,
            name = [ "PV" "EE" ],
            xlabel = "obs_time",
            ylabel = "price (USD)",
            width = 80,
            height = 30,
        )
        println()
        display(plt)
        println()
    end

    @testset "Vanilla swap profile." begin
        model = DiffFusion.simple_model("Std", setup_models(ch_full))
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(model, ch_full, times, n_paths, with_progress_bar = true)
        path = DiffFusion.path(sim, ts_list, context, DiffFusion.LinearPathInterpolation)
        #
        example = YAML.load(yaml_string, dicttype=OrderedDict{String,Any})
        #
        DiffFusion.Examples.portfolio!(example, 10)
        DiffFusion.Examples.display_portfolio(example)
        #
        usd_swap = example["portfolio"][4]
        effective_time = usd_swap[2].cashflows[1].period_times[1]
        maturity_time = usd_swap[2].cashflows[end].period_times[end]
        notional = usd_swap[1].notionals[1]
        fixed_rate = usd_swap[1].cashflows[1].fixed_rate
        println("Effective time: " * string(effective_time))
        println("Maturity time:  " * string(maturity_time))
        println("Notional:       " * string(notional))
        println("Fixed rate:     " * string(fixed_rate))
        #
        usd_swap_1 = [ usd_swap[1], usd_swap[1], usd_swap[1], usd_swap[2]]  # make the swap more at par
        usd_swap_2 = [ usd_swap[1], usd_swap[1], usd_swap[1], usd_swap[1], usd_swap[2]]  # make the swap more at par
        obs_times = 0.0:1.0/12:7.0
        scens_1 = DiffFusion.scenarios(usd_swap_1, obs_times, path, "")
        plot_swap(scens_1, "USD Swap_1")
        #
        all_swaps = vcat(example["portfolio"]...)
        obs_times = 0.0:1.0/4:10.0
        scens = DiffFusion.scenarios(all_swaps, obs_times, path, "")
        plot_swap(scens, "Portfolio")
        #
    end


    """
        scenarios_mt(
            legs::AbstractVector,
            times::AbstractVector,
            path::Path,
            discount_curve_key::Union{String,Nothing};
            with_progress_bar::Bool = true,
            )
    
    Multi-threaded calculate `ScenarioCube` for a vector of `CashFlowLeg` objects and
    a vector of scenario observation `times`.
    """
    function scenarios_mt(
        legs::AbstractVector,
        times::AbstractVector,
        path::DiffFusion.Path,
        discount_curve_key::Union{String,Nothing};
        with_progress_bar::Bool = true,
        )
        #
        dist = zeros(Threads.nthreads())
        #
        leg_aliases = [ DiffFusion.alias(l) for l in legs ]
        numeraire_context_key = path.context.numeraire.context_key
        #
        X = zeros(length(path), length(times), length(legs))
        Threads.@threads :static for iter in shuffle(collect(0:(length(times) * length(legs))-1))
            j = (iter ÷ length(legs)) + 1
            k = (iter % length(legs)) + 1
            payoffs = DiffFusion.discounted_cashflows(legs[k], times[j])
            for payoff in payoffs
                X[:,j,k] += payoff(path)
                dist[Threads.threadid()] += 1
            end
        end
        if !isnothing(discount_curve_key)
            num = zeros(length(path), length(times))
            Threads.@threads for j = 1:length(times)
                num[:, j] = DiffFusion.numeraire(path, times[j], discount_curve_key)
            end
            num = reshape(num, size(num)[1], size(num)[2], 1)  # allow broadcasting
            X ./= num
        end
        dist ./= sum(dist)
        dist_string = "Work@Thread: ["
        for d in dist
            dist_string *= @sprintf("%.2f, ", d)
        end
        dist_string = dist_string[1:end-2] * "]"
        @info dist_string
        return DiffFusion.ScenarioCube(X, times, leg_aliases, numeraire_context_key, discount_curve_key)
    end


    @testset "Multi-threading scenario valuation." begin
        model = DiffFusion.simple_model("Std", setup_models(ch_full))
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(model, ch_full, times, n_paths, with_progress_bar = true)
        path = DiffFusion.path(sim, ts_list, context, DiffFusion.LinearPathInterpolation)
        #
        example = YAML.load(yaml_string, dicttype=OrderedDict{String,Any})
        #
        DiffFusion.Examples.portfolio!(example, 10)
        DiffFusion.Examples.display_portfolio(example)
        #
        all_swaps = vcat(example["portfolio"]...)
        obs_times = 0.0:1.0/4:10.0
        #
        @info "Run single-threaded scenario valuation..."
        @time scens_st = DiffFusion.scenarios(all_swaps, obs_times, path, "", with_progress_bar=false)
        @info "Run multi-threaded scenario valuation..."
        @time scens_mt = scenarios_mt(all_swaps, obs_times, path, "")
        @test scens_mt.X == scens_st.X
        # println(maximum(abs.(scens_mt.X - scens_st.X)))
        #
    end


end