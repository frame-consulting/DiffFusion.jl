
"""
    fixed_rate_leg(
        alias::String,
        effective_time::ModelTime,
        maturity_time::ModelTime,
        coupons_per_year::Int,
        fixed_rate::ModelValue,
        notional::ModelValue,
        discount_curve_key::String,
        fx_key::Union{String, Nothing} = nothing,
        payer_receiver = 1.0,
        )

Create a fixed rate cash flow leg.
"""
function fixed_rate_leg(
    alias::String,
    effective_time::ModelTime,
    maturity_time::ModelTime,
    coupons_per_year::Int,
    fixed_rate::ModelValue,
    notional::ModelValue,
    discount_curve_key::String,
    fx_key::Union{String, Nothing} = nothing,
    payer_receiver = 1.0,
    )
    #
    schedule = effective_time:1.0/coupons_per_year:maturity_time
    coupons = [
        DiffFusion.FixedRateCoupon(e, fixed_rate, e-s)
        for (s,e) in zip(schedule[begin:end-1], schedule[begin+1:end])
    ]
    #
    notionals = notional * ones(length(coupons))
    return DiffFusion.cashflow_leg(alias, coupons, notionals, discount_curve_key, fx_key, payer_receiver)
end

"""
    simple_rate_leg(
        alias::String,
        effective_time::ModelTime,
        maturity_time::ModelTime,
        coupons_per_year::Int,
        forward_curve_key::String,
        fixing_key::Union{String, Nothing},
        spread_rate::Union{ModelValue, Nothing},
        notional::ModelValue,
        discount_curve_key::String,
        fx_key::Union{String, Nothing} = nothing,
        payer_receiver = 1.0,
        )

Create a Libor cash flow leg.
"""
function simple_rate_leg(
    alias::String,
    effective_time::ModelTime,
    maturity_time::ModelTime,
    coupons_per_year::Int,
    forward_curve_key::String,
    fixing_key::Union{String, Nothing},
    spread_rate::Union{ModelValue, Nothing},
    notional::ModelValue,
    discount_curve_key::String,
    fx_key::Union{String, Nothing} = nothing,
    payer_receiver = 1.0,
    )
    #
    act_360_adj = 365.0/360.0
    schedule = effective_time:1.0/coupons_per_year:maturity_time
    coupons = [
        DiffFusion.SimpleRateCoupon(s, s, e, e, (e-s)*act_360_adj, forward_curve_key, fixing_key, spread_rate)
        for (s,e) in zip(schedule[begin:end-1], schedule[begin+1:end])
    ]
    #
    notionals = notional * ones(length(coupons))
    return DiffFusion.cashflow_leg(alias, coupons, notionals, discount_curve_key, fx_key, payer_receiver)
end

"""
    compounded_rate_leg(
        alias::String,
        effective_time::ModelTime,
        maturity_time::ModelTime,
        coupons_per_year::Int,
        forward_curve_key::String,
        fixing_key::Union{String, Nothing},
        spread_rate::Union{ModelValue, Nothing},
        notional::ModelValue,
        discount_curve_key::String,
        fx_key::Union{String, Nothing} = nothing,
        payer_receiver = 1.0,
        )

Create a RFR compounded leg.
"""
function compounded_rate_leg(
    alias::String,
    effective_time::ModelTime,
    maturity_time::ModelTime,
    coupons_per_year::Int,
    forward_curve_key::String,
    fixing_key::Union{String, Nothing},
    spread_rate::Union{ModelValue, Nothing},
    notional::ModelValue,
    discount_curve_key::String,
    fx_key::Union{String, Nothing} = nothing,
    payer_receiver = 1.0,
    )
    #
    daily_step = 1.0/252 # average business day
    act_360_adj = 365.0/360.0
    schedule = effective_time:1.0/coupons_per_year:maturity_time
    in_period_times = [
        s:daily_step:e for (s,e) in zip(schedule[begin:end-1], schedule[begin+1:end])
    ]
    in_period_year_fractions = [
        daily_step * act_360_adj * ones(length(times)-1)
        for times in in_period_times
    ]
        coupons = [
        DiffFusion.CompoundedRateCoupon(times, yfs, e, forward_curve_key, fixing_key, spread_rate)
        for (s,e,times,yfs) in zip(schedule[begin:end-1], schedule[begin+1:end], in_period_times, in_period_year_fractions)
    ]
    #
    notionals = notional * ones(length(coupons))
    return DiffFusion.cashflow_leg(alias, coupons, notionals, discount_curve_key, fx_key, payer_receiver)
end


"""
    random_swap(example::OrderedDict{String,Any}, type_key::Union{String,Nothing} = nothing)

Sample a random swap.
"""
function random_swap(example::OrderedDict{String,Any}, type_key::Union{String,Nothing} = nothing)
    config = example["config/instruments"]
    if isnothing(type_key)
        type_key = config["types"][rand(1:length(config["types"]))]
    end
    inst_dict = config[type_key]
    @assert inst_dict["type"] in ("VANILLA", "BASIS-MTM")  # supported types
    swap_alias = type_key * "-" * randstring(6)
    if inst_dict["type"] == "VANILLA"
        effective_time = rand(-1.0:1/360:1.0)
        maturity_time = effective_time + rand(inst_dict["min_maturity"]:1.0:inst_dict["max_maturity"])
        notional = rand(inst_dict["min_notional"]:inst_dict["min_notional"]:inst_dict["max_notional"])
        #
        fixed_leg_dict = inst_dict["fixed_leg"]
        fixed_rate = rand(fixed_leg_dict["min_rate"]:fixed_leg_dict["min_rate"]:fixed_leg_dict["max_rate"])
        payer_receiver = rand(-1:2:1)
        fixed_leg = fixed_rate_leg(
            swap_alias * "-1",
            effective_time,
            maturity_time,
            fixed_leg_dict["coupons_per_year"],
            fixed_rate,
            notional,
            inst_dict["discount_curve_key"],
            inst_dict["fx_key"],
            payer_receiver
        )
        #
        float_leg_dict = inst_dict["float_leg"]
        @assert float_leg_dict["coupon_type"] in ("SIMPLE", "COMPOUNDED")
        if float_leg_dict["coupon_type"] == "SIMPLE"
            leg_function = simple_rate_leg
        end
        if float_leg_dict["coupon_type"] == "COMPOUNDED"
            leg_function = compounded_rate_leg
        end
        float_leg = leg_function(
            swap_alias * "-2",
            effective_time,
            maturity_time,
            float_leg_dict["coupons_per_year"],
            float_leg_dict["forward_curve_key"],
            float_leg_dict["fixing_key"],
            nothing,
            notional,
            inst_dict["discount_curve_key"],
            inst_dict["fx_key"],
            -payer_receiver,
        )
        #
        return [fixed_leg, float_leg]
    end
    if inst_dict["type"] == "BASIS-MTM"
        effective_time = rand(-1.0:1/360:1.0)
        maturity_time = effective_time + rand(inst_dict["min_maturity"]:1.0:inst_dict["max_maturity"])
        notional = rand(inst_dict["min_notional"]:inst_dict["min_notional"]:inst_dict["max_notional"])
        #
        for_leg_dict = inst_dict["for_leg"]
        spread_rate = rand(for_leg_dict["min_spread"]:for_leg_dict["min_spread"]:for_leg_dict["max_spread"])
        payer_receiver = rand(-1:2:1)
        @assert for_leg_dict["coupon_type"] in ("SIMPLE", "COMPOUNDED")
        if for_leg_dict["coupon_type"] == "SIMPLE"
            leg_function = simple_rate_leg
        end
        if for_leg_dict["coupon_type"] == "COMPOUNDED"
            leg_function = compounded_rate_leg
        end
        for_leg = leg_function(
            swap_alias * "-1",
            effective_time,
            maturity_time,
            for_leg_dict["coupons_per_year"],
            for_leg_dict["forward_curve_key"],
            for_leg_dict["fixing_key"],
            spread_rate,
            notional,
            for_leg_dict["discount_curve_key"],
            for_leg_dict["fx_key"],
            payer_receiver,
        )
        #
        dom_leg_dict = inst_dict["dom_leg"]
        @assert dom_leg_dict["coupon_type"] in ("SIMPLE", "COMPOUNDED")
        if dom_leg_dict["coupon_type"] == "SIMPLE"
            leg_function = simple_rate_leg
        end
        if dom_leg_dict["coupon_type"] == "COMPOUNDED"
            leg_function = compounded_rate_leg
        end
        dom_leg = leg_function(
            swap_alias * "-2",
            effective_time,
            maturity_time,
            dom_leg_dict["coupons_per_year"],
            dom_leg_dict["forward_curve_key"],
            dom_leg_dict["fixing_key"],
            nothing,
            1.0, # not used
            dom_leg_dict["discount_curve_key"],
            dom_leg_dict["fx_key"],
            -payer_receiver,
        )
        dom_leg_mtm = DiffFusion.mtm_cashflow_leg(
            swap_alias * "-2",
            dom_leg,
            notional,
            effective_time,
            for_leg_dict["discount_curve_key"],
            for_leg_dict["fx_key"],
        )
        #
        return [for_leg, dom_leg_mtm]
    end
end

"""
    portfolio!(example::OrderedDict{String,Any}, n_swaps::Int = 10)

Create a portfolio of swaps and store it in the dictionary.
"""
function portfolio!(example::OrderedDict{String,Any}, n_swaps::Int = 10)
    if haskey(example, "portfolio")
        return example["portfolio"]
    end
    config = example["config/instruments"]
    if haskey(config, "seed")
        Random.seed!(config["seed"])
    end
    portfolio = [
        random_swap(example)
        for k in 1:n_swaps
    ]
    example["portfolio"] = portfolio
    return portfolio
end

"""
Print portfolio in terminal.
"""
function display_portfolio(example::OrderedDict{String,Any})
    if !haskey(example,"portfolio")
        println("No portfolio available.")
        return
    end
    for swap in example["portfolio"]
        println([ DiffFusion.alias(swap[1]), DiffFusion.alias(swap[2]) ])
    end
end

