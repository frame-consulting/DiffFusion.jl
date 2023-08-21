
"""
    struct MtMCashFlowLeg <: CashFlowLeg
        alias::String
        cashflows::AbstractVector
        intitial_notional::ModelValue
        curve_key_dom::String
        curve_key_for::String
        fx_key_dom::Union{String, Nothing}
        fx_key_for::Union{String, Nothing}
        fx_reset_times::AbstractVector
        fx_pay_times::AbstractVector
        payer_receiver::ModelValue
    end

A mark-to-market (MtM) cross currency cash flow leg adds notional resets
to the cash flow payments.

Notional resets are calculated from FX rates at reset times.

We consider a setting with numeraire currency, domestic currency and
foreign currency.

Cash flows are denominated in domestic currency. Initial notional is
expressed in foreign currency and simulation is modelled in numeraire
currency.

We denote `fx_key_for` the FOR-NUM asset key and `fx_key_dom` the
DOM-NUM asset key.

FX rates for notional exchange are fixed at `fx_reset_times` and notional
cash flows are exchanged at `fx_pay_times`. The very first notional exchange
is not modelled because it is either in the past or foreign and domestic
notional exchange offset each other.

As a consequence, we have one `fx_reset_time` and one `fx_pay_time` per cash flow.
The `fx_reset_time` is at (or before) the start of the coupon period and
`fx_pay_time` is at (or after) the end of the coupon period.

"""
struct MtMCashFlowLeg <: CashFlowLeg
    alias::String
    cashflows::AbstractVector
    intitial_notional::ModelValue
    curve_key_dom::String
    curve_key_for::String
    fx_key_dom::Union{String, Nothing}
    fx_key_for::Union{String, Nothing}
    fx_reset_times::AbstractVector
    fx_pay_times::AbstractVector
    payer_receiver::ModelValue
end


"""
    mtm_cashflow_leg(
        alias::String,
        cashflows::AbstractVector,
        intitial_notional::ModelValue,
        curve_key_dom::String,
        curve_key_for::String,
        fx_key_dom::Union{String, Nothing},
        fx_key_for::Union{String, Nothing},
        fx_reset_times::AbstractVector,
        fx_pay_times::AbstractVector,
        payer_receiver::ModelValue,
        )

Create a MTM cash flow leg.
"""
function mtm_cashflow_leg(
    alias::String,
    cashflows::AbstractVector,
    intitial_notional::ModelValue,
    curve_key_dom::String,
    curve_key_for::String,
    fx_key_dom::Union{String, Nothing},
    fx_key_for::Union{String, Nothing},
    fx_reset_times::AbstractVector,
    fx_pay_times::AbstractVector,
    payer_receiver::ModelValue,
    )
    #
    @assert length(cashflows) > 0
    @assert intitial_notional > 0
    @assert length(fx_reset_times) == length(cashflows)
    @assert length(fx_pay_times) == length(cashflows)
    @assert payer_receiver in (-1.0, 1.0)
    #
    @assert fx_pay_times[1] >= fx_reset_times[1]
    for k in 2:length(cashflows)
        @assert pay_time(cashflows[k]) >  pay_time(cashflows[k-1])
        @assert fx_pay_times[k]        >= fx_reset_times[k]
        @assert fx_pay_times[k]        >  fx_pay_times[k-1]
        @assert fx_reset_times[k]      >  fx_reset_times[k-1]
    end
    return MtMCashFlowLeg(alias, cashflows, intitial_notional, curve_key_dom, curve_key_for,
        fx_key_dom, fx_key_for, fx_reset_times, fx_pay_times, payer_receiver)
end

"""
    mtm_cashflow_leg(
        alias::String,
        leg::DeterministicCashFlowLeg,
        intitial_notional::ModelValue,  # in foreign currency
        initial_reset_time::ModelValue,
        curve_key_for::String,
        fx_key_for::Union{String, Nothing},
        )

Create a MtM cash flow leg from a deterministic leg.
"""
function mtm_cashflow_leg(
    alias::String,
    leg::DeterministicCashFlowLeg,
    intitial_notional::ModelValue,  # in foreign currency
    initial_reset_time::ModelValue,
    curve_key_for::String,
    fx_key_for::Union{String, Nothing},
    )
    #
    fx_pay_times = [ pay_time(cf) for cf in leg.cashflows ]
    fx_reset_times = vcat(
        [ initial_reset_time ], fx_pay_times[begin:end-1]
    )
    return mtm_cashflow_leg(
        alias,
        leg.cashflows,
        intitial_notional,
        leg.curve_key,
        curve_key_for,
        leg.fx_key,
        fx_key_for,
        fx_reset_times,
        fx_pay_times,
        leg.payer_receiver,
    )
end


"""
    future_cashflows(leg::MtMCashFlowLeg, obs_time::ModelTime)

Calculate the list of future undiscounted payoffs in numeraire currency.
"""
function future_cashflows(leg::MtMCashFlowLeg, obs_time::ModelTime)
    # we need the FX rate FOR-DOM via triangulation.
    fx_for_dom(t) = begin
        if isnothing(leg.fx_key_dom) && isnothing(leg.fx_key_for)
            return 1.0
        end
        if isnothing(leg.fx_key_dom)
            return Asset(t, leg.fx_key_for)
        end
        if isnothing(leg.fx_key_for)
            return 1.0 / Asset(t, leg.fx_key_dom)
        end
        return Asset(t, leg.fx_key_for) / Asset(t, leg.fx_key_dom)
    end
    payoffs = Payoff[]
    for (k, cf) in enumerate(leg.cashflows)
        if pay_time(cf) > obs_time
            dom_notional = fx_for_dom(leg.fx_reset_times[k]) * (leg.payer_receiver * leg.intitial_notional)
            P = dom_notional * amount(cf)
            if !isnothing(leg.fx_key_dom)
                P = Asset(pay_time(cf), leg.fx_key_dom) * P
            end
            push!(payoffs, Pay(P, pay_time(cf)))
        end
        if leg.fx_pay_times[k] > obs_time
            P = (fx_for_dom(leg.fx_reset_times[k]) - fx_for_dom(leg.fx_pay_times[k]))
            P = P * (leg.payer_receiver * leg.intitial_notional)
            if !isnothing(leg.fx_key_dom)
                P = Asset(leg.fx_pay_times[k], leg.fx_key_dom) * P
            end
            if !isa(P, Payoff)
                P = Fixed(P)
            end
            push!(payoffs, Pay(P, leg.fx_pay_times[k]))
        end
    end
    return payoffs
end


"""
    discounted_cashflows(leg::MtMCashFlowLeg, obs_time::ModelTime)

Calculate the list of future discounted payoffs in numeraire currency.
"""
function discounted_cashflows(leg::MtMCashFlowLeg, obs_time::ModelTime)
    # we need the FX rate FOR-DOM via triangulation.
    fx_for_dom(t) = begin
        if isnothing(leg.fx_key_dom) && isnothing(leg.fx_key_for)
            return 1.0
        end
        if isnothing(leg.fx_key_dom)
            return Asset(t, leg.fx_key_for)
        end
        if isnothing(leg.fx_key_for)
            return 1.0 / Asset(t, leg.fx_key_dom)
        end
        return Asset(t, leg.fx_key_for) / Asset(t, leg.fx_key_dom)
    end
    fwd_fx_for_dom(t) = begin
        if t <= obs_time
            return fx_for_dom(t)  #  rate is fixed already
        end
        # we must not look into the future and use T-forward expectation
        return fx_for_dom(obs_time) * ZeroBond(obs_time, t, leg.curve_key_for) / ZeroBond(obs_time, t, leg.curve_key_dom)
    end
    payoffs = Payoff[]
    for (k, cf) in enumerate(leg.cashflows)
        if pay_time(cf) > obs_time
            dom_notional = fwd_fx_for_dom(leg.fx_reset_times[k]) * (leg.payer_receiver * leg.intitial_notional)
            P = dom_notional * ZeroBond(obs_time, pay_time(cf), leg.curve_key_dom) * expected_amount(cf, obs_time)
            if !isnothing(leg.fx_key_dom)
                P = Asset(obs_time, leg.fx_key_dom) * P
            end
            push!(payoffs, Pay(P, obs_time))
        end
        if leg.fx_pay_times[k] > obs_time
            P = (fwd_fx_for_dom(leg.fx_reset_times[k]) - fwd_fx_for_dom(leg.fx_pay_times[k]))
            P = ZeroBond(obs_time, leg.fx_pay_times[k], leg.curve_key_dom) * P * (leg.payer_receiver * leg.intitial_notional)
            if !isnothing(leg.fx_key_dom)
                P =  Asset(obs_time, leg.fx_key_dom) * P
            end
            if !isa(P, Payoff)
                P = Fixed(P)
            end
            push!(payoffs, Pay(P, obs_time))
        end
    end
    return payoffs
end
