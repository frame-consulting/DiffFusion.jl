
"""
    implied_swaption_volatilities(
        p::AbstractPath,
        expiry_time::ModelTime,
        fixed_times::AbstractVector,
        fixed_weights::AbstractVector,
        disc_key::String,
        relative_strikes::AbstractVector,
        )

Calculate implied normal volatilities for a European swaption.

We assume projection curve equals discount curve, i.e. no tenor basis.
"""
function implied_swaption_volatilities(
    p::AbstractPath,
    expiry_time::ModelTime,
    fixed_times::AbstractVector,
    fixed_weights::AbstractVector,
    disc_key::String,
    relative_strikes::AbstractVector,
    )
    #
    @assert length(fixed_weights) > 0
    @assert length(fixed_times) == length(fixed_weights) + 1
    @assert all(expiry_time .≤ fixed_times)
    @assert length(relative_strikes) > 0
    #
    A = Annuity(expiry_time, fixed_times, fixed_weights, disc_key)
    N = Numeraire(expiry_time, disc_key)
    (annuity, float_leg) = annuity_and_leg_at(A, p)
    num = at(N, p)
    #
    annuity_0 = mean(annuity ./ num)
    float_leg_0 = mean(float_leg ./ num)
    swap_rate = float_leg_0 / annuity_0
    #
    call_put = reshape([ (rel_strike < 0) ? -1 : 1 for rel_strike in relative_strikes ], (1,:))
    abs_strikes = reshape(swap_rate .+ relative_strikes, (1,:))
    #
    option_0 = mean(max.(call_put .* (float_leg .- abs_strikes .* annuity), 0.0) ./ num, dims=1)
    option_1 = vec(option_0) ./ annuity_0
    #
    vols = [
        bachelier_implied_volatility(option, strike, swap_rate, expiry_time, cp)
        for (option, strike, cp) in zip(option_1, abs_strikes, call_put)
    ]
    return vols
end


"""
    implied_swaption_volatilities(
        sim::Simulation,
        yts::YieldTermstructure,
        expiry_time::ModelTime,
        fixed_times::AbstractVector,
        fixed_weights::AbstractVector,
        relative_strikes::AbstractVector,
        )

Calculate implied normal volatilities for a European swaption.

We assume projection curve equals discount curve, i.e. no tenor basis.
"""
function implied_swaption_volatilities(
    sim::Simulation,
    yts::YieldTermstructure,
    expiry_time::ModelTime,
    fixed_times::AbstractVector,
    fixed_weights::AbstractVector,
    relative_strikes::AbstractVector,
    )
    #
    ccy_key = "CCY"
    ctx = context(
        "Std",
        numeraire_entry(ccy_key, model_alias(sim.model)[begin], alias(yts)),
        [ rates_entry(ccy_key, model_alias(sim.model)[begin], alias(yts)), ]
    )
    p = path(sim, [yts], ctx, LinearPathInterpolation)
    #
    return implied_swaption_volatilities(
        p,
        expiry_time,
        fixed_times,
        fixed_weights,
        ccy_key,
        relative_strikes,
    )
end