
"""
    struct CashBalance <: CashFlowLeg
        alias::String
        notional::ModelValue
        fx_key::Union{String, Nothing}
        payer_receiver::ModelValue
        maturity_time::Union{Nothing, ModelTime}
    end

A CashLeg represents a constant cash balance in domestic or foreign corrency.
"""
struct CashBalanceLeg <: CashFlowLeg
    alias::String
    notional::ModelValue
    fx_key::Union{String, Nothing}
    payer_receiver::ModelValue
    maturity_time::Union{Nothing, ModelTime}
end


"""
    cash_balance_leg(
        alias::String,
        notional::ModelValue,
        fx_key::Union{String, Nothing} = nothing,
        payer_receiver::ModelValue = +1.0,
        maturity_time::Union{Nothing, ModelTime} = nothing
        )

Create a CashBalance object.
"""
function cash_balance_leg(
    alias::String,
    notional::ModelValue,
    fx_key::Union{String, Nothing} = nothing,
    payer_receiver::ModelValue = +1.0,
    maturity_time::Union{Nothing, ModelTime} = nothing
    )
    #
    @assert notional > 0.0
    @assert payer_receiver in (+1.0, -1.0)
    return CashBalanceLeg(alias, notional, fx_key, payer_receiver, maturity_time)
end


"""
    future_cashflows(leg::CashBalanceLeg, obs_time::ModelTime)

Calculate the list of future undiscounted payoffs in numeraire currency.
"""
function future_cashflows(leg::CashBalanceLeg, obs_time::ModelTime)
    if !isnothing(leg.maturity_time) && (obs_time ≥ leg.maturity_time)
        return Payoff[]
    end
    P = Fixed(leg.payer_receiver * leg.notional)
    if !isnothing(leg.fx_key)
        P = Asset(obs_time, leg.fx_key) * P
    end
    return [ Pay(P, obs_time) ]
end


"""
    discounted_cashflows(leg::CashBalanceLeg, obs_time::ModelTime)

Calculate the list of future discounted payoffs in numeraire currency.
"""
discounted_cashflows(leg::CashBalanceLeg, obs_time::ModelTime) = future_cashflows(leg, obs_time)


"""
An AssetLeg represents a position in a tradeable asset. Such tradeable asset can be, e.g.,
a share price, index price or an (FOR-DOM) FX rate where DOM currency differs from
numeraire currency. 
"""
struct AssetLeg <: CashFlowLeg
    alias::String
    asset_key::String
    amount::ModelValue
    fx_key::Union{String, Nothing}
    payer_receiver::ModelValue
    maturity_time::Union{Nothing, ModelTime}
end


function asset_leg(
    alias::String,
    asset_key::String,
    amount::ModelValue,
    fx_key::Union{String, Nothing} = nothing,
    payer_receiver::ModelValue = +1.0,
    maturity_time::Union{Nothing, ModelTime} = nothing,
    )
    #
    @assert amount > 0.0
    @assert payer_receiver in (+1.0, -1.0)
    return AssetLeg(alias, asset_key, amount, fx_key, payer_receiver, maturity_time)
end


"""
    future_cashflows(leg::AssetLeg, obs_time::ModelTime)

Calculate the list of future undiscounted payoffs in numeraire currency.
"""
function future_cashflows(leg::AssetLeg, obs_time::ModelTime)
    if !isnothing(leg.maturity_time) && (obs_time ≥ leg.maturity_time)
        return Payoff[]
    end
    P = (leg.payer_receiver * leg.amount) * Asset(obs_time, leg.asset_key)
    if !isnothing(leg.fx_key)
        P = Asset(obs_time, leg.fx_key) * P
    end
    return [ Pay(P, obs_time) ]
end


"""
    discounted_cashflows(leg::AssetLeg, obs_time::ModelTime)

Calculate the list of future discounted payoffs in numeraire currency.
"""
discounted_cashflows(leg::AssetLeg, obs_time::ModelTime) = future_cashflows(leg, obs_time)

