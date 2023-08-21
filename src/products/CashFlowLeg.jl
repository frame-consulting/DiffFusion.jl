

"""
    abstract type CashFlowLeg end

A `CashFlowLeg` combines `CashFlow` objects in a single currency and adds
notional and payer/receiver information and discounting.

We apply the convention that notionals are non-negative and cash flows
are modelled from the receiving counter party perspective. This does
include the exceptions of negative spread cash flows or negative
notional exchange cash flows.
"""
abstract type CashFlowLeg end

"""
    alias(leg::CashFlowLeg)

Return the leg alias
"""
alias(leg::CashFlowLeg) = leg.alias

"""
    future_cashflows(leg::CashFlowLeg, obs_time::ModelTime)

Calculate the list of future undiscounted payoffs in numeraire currency.
"""
function future_cashflows(leg::CashFlowLeg, obs_time::ModelTime)
    error("CashFlowLeg needs to implement future_cashflows method.")
end

"""
    discounted_cashflows(leg::CashFlowLeg, obs_time::ModelTime)

Calculate the list of future discounted payoffs in numeraire currency.
"""
function discounted_cashflows(leg::CashFlowLeg, obs_time::ModelTime)
    error("CashFlowLeg needs to implement discounted_cashflows method.")
end


"""
    struct DeterministicCashFlowLeg <: CashFlowLeg
        alias::String
        cashflows::AbstractVector
        notionals::AbstractVector
        curve_key::String
        fx_key::Union{String, Nothing}
        payer_receiver::ModelValue
    end

A DeterministicCashFlowLeg models legs with deterministic notionals.
"""
struct DeterministicCashFlowLeg <: CashFlowLeg
    alias::String
    cashflows::AbstractVector
    notionals::AbstractVector
    curve_key::String
    fx_key::Union{String, Nothing}
    payer_receiver::ModelValue
end

"""
    cashflow_leg(
        alias::String,
        cashflows::AbstractVector,
        notionals::AbstractVector,
        curve_key::Union{String, Nothing} = nothing,
        fx_key::Union{String, Nothing} = nothing,
        payer_receiver = 1.0,
        )

Create a DeterministicCashFlowLeg.
"""
function cashflow_leg(
    alias::String,
    cashflows::AbstractVector,
    notionals::AbstractVector,
    curve_key::Union{String, Nothing} = nothing,
    fx_key::Union{String, Nothing} = nothing,
    payer_receiver = 1.0,
    )
    #
    @assert length(cashflows) > 0
    @assert length(cashflows) == length(notionals)
    @assert payer_receiver in (-1.0, 1.0)
    if isnothing(curve_key)
        # try to infer curve key from the cashflows
        @assert hasproperty(cashflows[begin], :curve_key)
        curve_key = cashflows[begin].curve_key
    end
    return DeterministicCashFlowLeg(alias, cashflows, notionals, curve_key, fx_key, payer_receiver)
end

"""
    cashflow_leg(
        alias::String,
        cashflows::AbstractVector,
        notional::ModelValue,
        curve_key::Union{String, Nothing} = nothing,
        fx_key::Union{String, Nothing} = nothing,
        payer_receiver = 1.0,
        )

Create a constant notional CashFlowLeg.
"""
function cashflow_leg(
    alias::String,
    cashflows::AbstractVector,
    notional::ModelValue,
    curve_key::Union{String, Nothing} = nothing,
    fx_key::Union{String, Nothing} = nothing,
    payer_receiver = 1.0,
    )
    #
    @assert length(cashflows) > 0
    @assert notional > 0.0
    notionals = notional * ones(length(cashflows))
    return cashflow_leg(alias, cashflows, notionals, curve_key, fx_key, payer_receiver)
end


"""
    future_cashflows(leg::DeterministicCashFlowLeg, obs_time::ModelTime)

Calculate the list of future undiscounted payoffs in numeraire currency.
"""
function future_cashflows(leg::DeterministicCashFlowLeg, obs_time::ModelTime)
    payoffs = Payoff[]
    for (cf, notional) in zip(leg.cashflows, leg.notionals)
        if pay_time(cf) > obs_time
            P = (leg.payer_receiver * notional) * amount(cf)
            if !isnothing(leg.fx_key)
                P = Asset(pay_time(cf), leg.fx_key) * P
            end
            push!(payoffs, Pay(P, pay_time(cf)))
        end
    end
    return payoffs
end


"""
    discounted_cashflows(leg::DeterministicCashFlowLeg, obs_time::ModelTime)

Calculate the list of future discounted payoffs in numeraire currency.
"""
function discounted_cashflows(leg::DeterministicCashFlowLeg, obs_time::ModelTime)
    payoffs = Payoff[]
    for (cf, notional) in zip(leg.cashflows, leg.notionals)
        if pay_time(cf) > obs_time
            P = (leg.payer_receiver * notional) * expected_amount(cf, obs_time)
            P = ZeroBond(obs_time, pay_time(cf), leg.curve_key) * P
            if !isnothing(leg.fx_key)
                P = Asset(obs_time, leg.fx_key) * P
            end
            push!(payoffs, Pay(P, obs_time))
        end
    end
    return payoffs
end
