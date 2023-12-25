
"""
This file contains methods for collateralised exposure calculation.

We follow the approaches in A. Green, XVA, 2016.
"""


"""
    collateral_call_times(
        Δt::ModelTime,
        first_call_time::ModelTime,
        last_call_time::ModelTime,
        )

Calculate margin call times. 

Margin frequency is represented as time difference between margin call times, `Δt`.

`first_call_time` is the first margin time greater/equal time-0 and `last_call_time`
is the last modelled margin call time.
"""
function collateral_call_times(
    Δt::ModelTime,
    first_call_time::ModelTime,
    last_call_time::ModelTime,
    )
    #
    @assert Δt > 0.0
    @assert first_call_time ≥ 0.0
    @assert last_call_time ≥ first_call_time
    times = first_call_time:Δt:last_call_time
    if first_call_time > 0.0
        times = vcat(0.0, times)
    end
    return times
end


"""
    market_values_for_csa(
        portfolio::ScenarioCube,
        obs_times::AbstractVector,
        fx_rates::Union{ScenarioCube, Nothing} = nothing
        )

Calculate future market values of a given portfolio in CSA currency. Result is
represented as `ScenarioCube`.

Market values of the `portfolio` are assumed in numeraire currency from a simulation.

`fx_rates` are simulated FOR-DOM exchange rates where FOR currency represents the CSA
currency and DOM currency represents the numeraire currency of the simulation.

`obs_times` represent the margin call times for which market values are required.
We implement linear interpolation of available market values.
"""
function market_values_for_csa(
    portfolio::ScenarioCube,
    obs_times::AbstractVector,
    fx_rates::Union{ScenarioCube, Nothing} = nothing
    )
    # collateral calculation is based on un-discouted (!) market values.
    @assert isnothing(portfolio.discount_curve_key)
    if !isnothing(fx_rates)
        isnothing(fx_rates.discount_curve_key)
    end
    #
    mv = aggregate(portfolio, false, true)
    if !isnothing(fx_rates)
        mv = mv / fx_rates
    end
    #
    mv_csa_list = [ interpolate_scenarios(t, mv) for t in obs_times ]
    mv_cube = concatenate_scenarios(mv_csa_list)
    return mv_cube
end


"""
    collateral_values_for_csa(
       portfolio::ScenarioCube,
       initial_collateral_balance::ModelValue,
       minimum_transfer_amount::ModelValue,
       threshold_amount::ModelValue,
       independent_amount::ModelValue,
       )

Calculate the collateral balance based on CSA parameters.

`portfolio` is assumed to be aggregated over legs and represents
un-discounted market values in CSA currency.

CSA parameters are all denominated in CSA currency (or base currency).

`initial_collateral_balance` is the (net-)balance of posted/received
collateral at time-0.

`minimum_transfer_amount` (MTA) is the minimum amount of collateral that is
exchanged at a collateral call time. Here, MTA is assumed equal for
bank and counterparty.

`threshold_amount` (TA) represents the maximum exposure of the portfolio
below which no collateral is posted. Here, TA is assumed
equal for bank and counterparty.

`independent_amount` represents a (net-)amount of collateral that is
posted/received independent of the portfolio market value.
"""
function collateral_values_for_csa(
    portfolio::ScenarioCube,
    initial_collateral_balance::ModelValue,
    minimum_transfer_amount::ModelValue,
    threshold_amount::ModelValue,
    independent_amount::ModelValue,
    )
    #
    @assert length(portfolio.leg_aliases) == 1
    @assert size(portfolio.X)[3] == 1
    @assert minimum_transfer_amount ≥ 0.0
    @assert threshold_amount ≥ 0.0
    #
    collateral_balance = initial_collateral_balance * ones((size(portfolio.X)[1], 1))
    for k in eachindex(portfolio.times)[2:end]
        V = portfolio.X[:,k,1]
        X = collateral_balance[:,end]
        # see A. Green, sec. 6.4.2
        T = abs.(V) .≥ threshold_amount  # threshold trigger, no collateral below TA
        # (positive) collateral posted by counterparty to bank
        AC = (V - X .- threshold_amount)
        AC = AC .* (AC .≥ minimum_transfer_amount)
        # (negative) collateral posted by bank to counterparty
        AB = (V - X .+ threshold_amount)
        AB = AB .* (AB .≤ -minimum_transfer_amount)
        #
        A = T .* (AC + AB) + (1 .- T) .* (-X)
        #
        collateral_balance = hcat(collateral_balance, X + A)
    end
    X = reshape(collateral_balance, size(portfolio.X)) .+ independent_amount
    leg_aliases = [ "CB[" * portfolio.leg_aliases[1] * "]" ]
    return ScenarioCube(X, portfolio.times, leg_aliases, portfolio.numeraire_context_key, portfolio.discount_curve_key)
end


"""
    effective_collateral_values(
        obs_times::AbstractVector,
        collateral_balance::ScenarioCube,
        margin_period_of_risk::ModelTime,
        )

Calculate the effective collateral balance per observation times.

The effective effective collateral balance is modelled as an additional
ScenarioCube which can be joined with the original portfolio ScenarioCube.
The resulting combined ScenarioCube represents the collateralised portfolio.

Portfolio observation times `obs_times` represent termination times
following a potential default.

`collateral_balance` represent un-discounted market values of the
collateral account from bank's perspective in CSA currency.
Collateral observation times are margin call times.

`margin_period_of_risk` (MPR) represents the modelled time
between default time τ and observation time t.

We make the following assumptions:

- No margin flows are paid during MPR.
- All trade flows are paid during MPR.

The modelled approach refers to the "Classical+" approach in Andersen/Pykhtin/Sokol, 2016.
"""
function effective_collateral_values(
    obs_times::AbstractVector,
    collateral_balance::ScenarioCube,
    margin_period_of_risk::ModelTime,
    )
    #
    idx = [
        searchsortedlast(collateral_balance.times, max(t - margin_period_of_risk, 0.0))
        for t in obs_times
    ]
    X = cat([ -collateral_balance.X[:, k:k, :] for k in idx ]..., dims=2)
    return ScenarioCube(X, obs_times, collateral_balance.leg_aliases, collateral_balance.numeraire_context_key, collateral_balance.discount_curve_key)
end


"""
    collateralised_portfolio(
        portfolio::ScenarioCube,
        fx_rates::Union{ScenarioCube, Nothing},
        margin_call_times::AbstractVector,
        initial_collateral_balance::ModelValue,
        minimum_transfer_amount::ModelValue,
        threshold_amount::ModelValue,
        independent_amount::ModelValue,
        margin_period_of_risk::ModelTime,
        )

Calculate a collateralised portfolio by joining the effective collateral balance.
"""
function collateralised_portfolio(
    portfolio::ScenarioCube,
    fx_rates::Union{ScenarioCube, Nothing},
    margin_call_times::AbstractVector,
    initial_collateral_balance::ModelValue,
    minimum_transfer_amount::ModelValue,
    threshold_amount::ModelValue,
    independent_amount::ModelValue,
    margin_period_of_risk::ModelTime,
    )
    #
    scens_agg = aggregate(portfolio, false, true)
    scens_csa = market_values_for_csa(scens_agg, margin_call_times, fx_rates)
    scens_coll_csa = collateral_values_for_csa(
        scens_csa,
        initial_collateral_balance,
        minimum_transfer_amount,
        threshold_amount,
        independent_amount,
    )
    scens_coll = effective_collateral_values(
        portfolio.times,
        scens_coll_csa,
        margin_period_of_risk,
    )
    if !isnothing(fx_rates)
        scens_coll = fx_rates * scens_coll
    end
    coll_portfolio = join_scenarios(portfolio, scens_coll)
    return coll_portfolio
end
