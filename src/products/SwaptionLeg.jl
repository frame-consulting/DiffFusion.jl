

"""
    @enum(
        SwaptionSettlement,
        SwaptionCashSettlement,
        SwaptionPhysicalSettlement,
    )

SwaptionSettlement specifies whether swaption terminates at settlement time
or whether it is converted into a physicl swap.

For `SwaptionCashSettlement` the cash price is calculated as model price,
i.e. physical price at expiry.
"""
@enum(
    SwaptionSettlement,
    SwaptionCashSettlement,
    SwaptionPhysicalSettlement,
)


"""
A European swaption referencing a Vanilla swap with forward looking or
backward looking rates.
"""
struct SwaptionLeg <: CashFlowLeg
    alias::String
    #
    expiry_time::ModelTime
    settlement_time::ModelTime
    float_coupons::AbstractVector
    fixed_coupons::AbstractVector
    payer_receiver::ModelValue
    swap_disc_curve_key::String
    settlement_type::SwaptionSettlement
    #
    notional::ModelValue
    swpt_disc_curve_key::String
    swpt_fx_key::Union{String, Nothing}
    swpt_long_short::ModelValue
    #
    fixed_times::AbstractVector
    fixed_weights::AbstractVector
    fixed_rate::ModelValue
    exercise_indicator::Payoff
end


"""
Create a swaption object.
"""
function SwaptionLeg(
    alias::String,
    #
    expiry_time::ModelTime,
    settlement_time::ModelTime,
    float_coupons::AbstractVector,
    fixed_coupons::AbstractVector,
    payer_receiver::ModelValue,
    swap_disc_curve_key::String,
    settlement_type::SwaptionSettlement,
    #
    notional::ModelValue,
    swpt_disc_curve_key::String = swap_disc_curve_key,
    swpt_fx_key::Union{String, Nothing} = nothing,
    swpt_long_short::ModelValue = +1.0,
    )
    #
    @assert expiry_time ≥ 0.0
    @assert expiry_time ≤ settlement_time
    @assert length(float_coupons) > 0
    float_coupon_type = typeof(float_coupons[1])
    @assert float_coupon_type in (SimpleRateCoupon, CompoundedRateCoupon)
    for cp in float_coupons
        @assert typeof(cp) == float_coupon_type
        if typeof(cp) == SimpleRateCoupon
            @assert expiry_time ≤ cp.fixing_time
        end
        if typeof(cp) == CompoundedRateCoupon
            @assert expiry_time ≤ cp.period_times[begin]
        end
    end
    #
    for cp in fixed_coupons
        @assert typeof(cp) == FixedRateCoupon
        @assert expiry_time ≤ cp.pay_time
    end
    #
    effective_time = nothing
    maturity_time = nothing
    if float_coupon_type == SimpleRateCoupon
        effective_time = min((cp.start_time for cp in float_coupons)...)
        maturity_time = max((cp.pay_time for cp in float_coupons)...)
        @assert effective_time == float_coupons[begin].start_time
        @assert maturity_time == float_coupons[end].pay_time
    end
    if float_coupon_type == CompoundedRateCoupon
        effective_time = min((cp.period_times[begin] for cp in float_coupons)...)
        maturity_time = max((cp.pay_time for cp in float_coupons)...)
        @assert effective_time == float_coupons[begin].period_times[begin]
        @assert maturity_time == float_coupons[end].pay_time
    end
    fixed_times = [cp.pay_time for cp in fixed_coupons]  # without effective time
    for (first, second) in zip(fixed_times[begin:end-1], fixed_times[begin+1:end])
        @assert first ≤ second
    end
    @assert effective_time ≤ fixed_times[begin]
    @assert maturity_time == fixed_times[end]
    fixed_times = vcat([effective_time], fixed_times)  # with effective time
    #
    fixed_weights = [cp.year_fraction for cp in fixed_coupons]
    @assert all(fixed_weights .> 0.0)  # no degenerated coupons
    #
    fixed_rate = fixed_coupons[begin].fixed_rate
    for cp in fixed_coupons
        @assert fixed_rate == cp.fixed_rate
        # maybe we could relax the constant rate requirement and add some averaging
        # methodology here.
    end
    #
    @assert payer_receiver in (+1.0, -1.0)
    #
    @assert notional > 0.0  # no degenerated leg
    @assert swpt_long_short in (+1.0, -1.0)
    #
    # we cashe the payoff for exercise decision to avoid repeated evaluations
    O = Swaption(
        expiry_time,
        expiry_time,
        settlement_time,
        [ forward_rate(cf, expiry_time) for cf in float_coupons ],
        fixed_times,
        fixed_weights,
        fixed_rate,
        payer_receiver,
        swap_disc_curve_key
    )
    exercise_indicator = Cache(O > 0.0)
    #
    return SwaptionLeg(
        alias,
        #
        expiry_time,
        settlement_time,
        float_coupons,
        fixed_coupons,
        payer_receiver,
        swap_disc_curve_key,
        settlement_type,
        #
        notional,
        swpt_disc_curve_key,
        swpt_fx_key,
        swpt_long_short,
        #
        fixed_times,
        fixed_weights,
        fixed_rate,
        exercise_indicator
        #
    )
end


"""
    future_cashflows(leg::SwaptionLeg, obs_time::ModelTime)

Calculate the list of future undiscounted payoffs in numeraire currency.
"""
function future_cashflows(leg::SwaptionLeg, obs_time::ModelTime)
    payoffs = Payoff[]
    if obs_time ≥ leg.fixed_times[end]
        return payoffs
    end
    if (leg.settlement_type==SwaptionCashSettlement) && (obs_time ≥ leg.settlement_time)
        return payoffs
    end
    #
    forward_rates = [ forward_rate(cf, leg.expiry_time) for cf in leg.float_coupons ]
    O = Swaption(
        leg.expiry_time,
        leg.expiry_time,
        leg.settlement_time,
        forward_rates,
        leg.fixed_times,
        leg.fixed_weights,
        leg.fixed_rate,
        leg.payer_receiver,
        leg.swap_disc_curve_key
    )
    if leg.settlement_type == SwaptionCashSettlement
        P = (leg.swpt_long_short * leg.notional) * O
        if !isnothing(leg.swpt_fx_key)
            P = Asset(leg.settlement_time, leg.swpt_fx_key) * P
        end
        push!(payoffs, Pay(P, leg.settlement_time))
    end
    if leg.settlement_type == SwaptionPhysicalSettlement
        E = leg.exercise_indicator
        for cf in leg.float_coupons
            if pay_time(cf) > obs_time
                P = (leg.swpt_long_short * leg.payer_receiver * leg.notional) * amount(cf) * E
                if !isnothing(leg.swpt_fx_key)
                    P = Asset(pay_time(cf), leg.swpt_fx_key) * P
                end
                push!(payoffs, Pay(P, pay_time(cf)))
            end
        end
        for cf in leg.fixed_coupons
            if pay_time(cf) > obs_time
                P = (-1.0 * leg.swpt_long_short * leg.payer_receiver * leg.notional) * amount(cf) * E  # pay/receive fixed rate
                if !isnothing(leg.swpt_fx_key)
                    P = Asset(pay_time(cf), leg.swpt_fx_key) * P
                end
                push!(payoffs, Pay(P, pay_time(cf)))
            end
        end
    end
    return payoffs
end


"""
    discounted_cashflows(leg::SwaptionLeg, obs_time::ModelTime)

Calculate the list of future discounted payoffs in numeraire currency.
"""
function discounted_cashflows(leg::SwaptionLeg, obs_time::ModelTime)
    payoffs = Payoff[]
    if obs_time ≥ leg.fixed_times[end]
        return payoffs
    end
    if (leg.settlement_type==SwaptionCashSettlement) && (obs_time ≥ leg.settlement_time)
        return payoffs
    end
    #
    forward_rates = [ forward_rate(cf, min(obs_time, leg.expiry_time)) for cf in leg.float_coupons ]
    O = Swaption(
        min(obs_time, leg.expiry_time),
        leg.expiry_time,
        leg.settlement_time,
        forward_rates,
        leg.fixed_times,
        leg.fixed_weights,
        leg.fixed_rate,
        leg.payer_receiver,
        leg.swap_disc_curve_key
    )
    if obs_time < leg.settlement_time
        P = (leg.swpt_long_short * leg.notional) * O
        P = ZeroBond(obs_time, leg.settlement_time, leg.swpt_disc_curve_key) * P  # option discounting
        if !isnothing(leg.swpt_fx_key)
            P = Asset(obs_time, leg.swpt_fx_key) * P
        end
        push!(payoffs, Pay(P, obs_time))
    end    
    if (obs_time ≥ leg.settlement_time) && (leg.settlement_type == SwaptionPhysicalSettlement)
        E = leg.exercise_indicator
        for cf in leg.float_coupons
            if pay_time(cf) > obs_time
                P = (leg.swpt_long_short * leg.payer_receiver * leg.notional) * expected_amount(cf, obs_time) * E
                P = ZeroBond(obs_time, pay_time(cf), leg.swap_disc_curve_key) * P  # swap discounting
                if !isnothing(leg.swpt_fx_key)
                    P = Asset(obs_time, leg.swpt_fx_key) * P
                end
                push!(payoffs, Pay(P, obs_time))
            end
        end
        for cf in leg.fixed_coupons
            if pay_time(cf) > obs_time
                P = (-1.0 * leg.swpt_long_short * leg.payer_receiver * leg.notional) * expected_amount(cf, obs_time) * E  # pay/receive fixed rate
                P = ZeroBond(obs_time, pay_time(cf), leg.swap_disc_curve_key) * P  # swap discounting
                if !isnothing(leg.swpt_fx_key)
                    P = Asset(obs_time, leg.swpt_fx_key) * P
                end
                push!(payoffs, Pay(P, obs_time))
            end
        end
    end
    return payoffs
end

