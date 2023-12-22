
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
        type_key = config["swap_types"][rand(1:length(config["swap_types"]))]
    end
    inst_dict = config[type_key]
    @assert inst_dict["type"] in ("VANILLA", "BASIS-MTM")  # supported types
    swap_alias = type_key * "-" * randstring(6)
    # common swap properties
    if haskey(inst_dict, "min_start") && haskey(inst_dict, "max_start")
        # forward-starting
        effective_time = rand(inst_dict["min_start"]:1.0:inst_dict["max_start"])
    else
        # (more-or-less) spot starting
        effective_time = rand(-1.0:1/360:1.0)
    end
    maturity_time = effective_time + rand(inst_dict["min_maturity"]:1.0:inst_dict["max_maturity"])
    notional = rand(inst_dict["min_notional"]:inst_dict["min_notional"]:inst_dict["max_notional"])
    #
    if inst_dict["type"] == "VANILLA"
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
    random_swaption(
        example::OrderedDict{String,Any},
        type_key::Union{String,Nothing} = nothing,
        )

Sample a random swap.
"""
function random_swaption(
    example::OrderedDict{String,Any},
    type_key::Union{String,Nothing} = nothing,
    )
    #
    config = example["config/instruments"]
    if isnothing(type_key)
        type_key = config["swaption_types"][rand(1:length(config["swaption_types"]))]
    end
    inst_dict = config[type_key]
    @assert inst_dict["type"] in ("VANILLA", )  # supported types
    swaption_alias = type_key * "-" * randstring(6)
    #
    swap = random_swap(example, type_key)
    #
    first_float_coupon = swap[2].cashflows[1]
    settlement_time = nothing
    if isa(first_float_coupon, DiffFusion.SimpleRateCoupon)
        settlement_time = first_float_coupon.fixing_time
    end
    if isa(first_float_coupon, DiffFusion.CompoundedRateCoupon)
        settlement_time = first_float_coupon.period_times[begin]
    end
    @assert !isnothing(settlement_time)  # wrong coupon type
    expiry_time = settlement_time
    #
    float_coupons = swap[2].cashflows
    fixed_coupons = swap[1].cashflows
    swaption_payer_receiver = swap[2].payer_receiver  # call/put
    swap_disc_curve_key = swap[1].curve_key
    #
    settlement_type = nothing
    if inst_dict["setlement_type"] == "CASH"
        settlement_type = DiffFusion.SwaptionCashSettlement
    end
    if inst_dict["setlement_type"] == "PHYSICAL"
        settlement_type = DiffFusion.SwaptionPhysicalSettlement
    end
    @assert !isnothing(settlement_type)
    #
    notional = swap[1].notionals[begin]
    swpt_disc_curve_key = swap_disc_curve_key
    swpt_fx_key = swap[1].fx_key
    swpt_long_short = rand(-1:2:1)
    #
    swaption = DiffFusion.SwaptionLeg(
        swaption_alias,
        expiry_time,
        settlement_time,
        float_coupons,
        fixed_coupons,
        swaption_payer_receiver,
        swap_disc_curve_key,
        settlement_type,
        notional,
        swpt_disc_curve_key,
        swpt_fx_key,
        swpt_long_short,
    )
    return [ swaption ]
end


"""
    portfolio!(
        example::OrderedDict{String,Any},
        n_swaps::Int = 10,
        n_swaptions::Int = 0,
        )

Create a portfolio of swaps and swaptions and store it in the dictionary.
"""
function portfolio!(
    example::OrderedDict{String,Any},
    n_swaps::Int = 10,
    n_swaptions::Int = 0,
    )
    #
    if haskey(example, "portfolio")
        return example["portfolio"]
    end
    config = example["config/instruments"]
    if haskey(config, "seed")
        Random.seed!(config["seed"])
    end
    swap_portfolio = [
        random_swap(example)
        for k in 1:n_swaps
    ]
    swaption_portfolio = [
        random_swaption(example)
        for k in 1:n_swaptions
    ]
    portfolio = vcat(
        swap_portfolio,
        swaption_portfolio,
    )
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

"""
    scenarios!(example::OrderedDict{String,Any})

Create the exposure scenarios for the portfolio.
"""
function scenarios!(example::OrderedDict{String,Any})
    if haskey(example, "scenarios")
        return example["scenarios"]
    end
    config = example["config/instruments"]
    @assert haskey(config, "obs_times")
    obs_times = config["obs_times"]
    if isa(obs_times, AbstractDict)
        obs_times = Vector(obs_times["start"]:obs_times["step"]:obs_times["stop"])
    end
    @assert isa(obs_times, Vector)
    #
    if haskey(config, "with_progress_bar")
        with_progress_bar = config["with_progress_bar"]
    else
        with_progress_bar = true
    end
    @assert typeof(with_progress_bar) == Bool
    #
    discount_curve_key = config["discount_curve_key"]
    #
    legs = vcat(portfolio!(example)...)
    path_ = path!(example)
    scens = DiffFusion.scenarios(legs, obs_times, path_, discount_curve_key, with_progress_bar=with_progress_bar)
    example["scenarios"] = scens
    return scens
end
