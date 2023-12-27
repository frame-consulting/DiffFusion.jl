

"""
    struct Optionlet <: Payoff
        obs_time::ModelTime
        expiry_time::ModelTime
        gearing_factor::Payoff
        forward_rate::Union{LiborRate, CompoundedRate}
        strike_rate::Payoff
        call_put::ModelValue
    end

The time-t forward price of an option paying [ϕ(R-K)]^+. Rate R is determined at `expiry_time`.
The rate R can be forward-looking or backward-looking.

forward price is calculated as expectation in T-forward measure where T corresponds to the
period end time. Conditioning (for time-t price) is on information at `obs_time`.

The rate R is written in terms of a compounding factor C and R = [G C - 1]/τ.
Here, G is an additional gearing factor to capture past OIS fixings.

Then, option payoff becomes G/τ [ϕ(C - (1 + τK)/G)]^+.
"""
struct Optionlet <: Payoff
    obs_time::ModelTime
    expiry_time::ModelTime
    gearing_factor::Payoff
    forward_rate::Union{LiborRate, CompoundedRate}
    strike_rate::Payoff
    call_put::ModelValue
end

"""
    Optionlet(
        obs_time_::ModelTime,
        expiry_time::ModelTime,
        forward_rate::Union{LiborRate, CompoundedRate},
        strike_rate::Payoff,
        call_put::ModelValue,
        gearing_factor::Payoff = Fixed(1.0),
        )

Create an `Optionlet` payoff.
"""
function Optionlet(
    obs_time_::ModelTime,
    expiry_time::ModelTime,
    forward_rate::Union{LiborRate, CompoundedRate},
    strike_rate::Payoff,
    call_put::ModelValue,
    gearing_factor::Payoff = Fixed(1.0),
    )
    #
    @assert obs_time(forward_rate) == obs_time_  # consistent forward rate
    @assert obs_time(strike_rate) ≤ obs_time_  # payoff must be time-t measurable
    @assert obs_time(gearing_factor) ≤ obs_time_
    if typeof(forward_rate) == LiborRate
        @assert expiry_time ≤ forward_rate.start_time
    end
    if typeof(forward_rate) == CompoundedRate
        @assert expiry_time == forward_rate.end_time
    end
    @assert call_put in (+1.0, -1.0)
    return Optionlet(obs_time_, expiry_time, gearing_factor, forward_rate, strike_rate, call_put)
end


"""
    obs_time(p::Optionlet)

Return Optionlet observation time.
"""
function obs_time(p::Optionlet)
    return p.obs_time
end


"""
    obs_times(p::Optionlet)

Return all Optionlet observation times. 
"""
function obs_times(p::Optionlet)
    times = Set(obs_time(p))
    times = union(times, obs_times(p.gearing_factor))
    times = union(times, obs_times(p.forward_rate))
    times = union(times, obs_times(p.strike_rate))
    return times
end


"""
    at(p::Optionlet, path::AbstractPath)

Evaluate a `Optionlet` at a given `path`, *X(omega)*.
"""
function at(p::Optionlet, path::AbstractPath)
    τ = p.forward_rate.year_fraction
    fac = at(p.gearing_factor, path) ./ τ
    C = 1.0 .+ τ .* at(p.forward_rate, path)
    K = (1.0 .+ τ .* at(p.strike_rate, path)) ./ at(p.gearing_factor, path)
    ν² = forward_rate_variance(
        path,
        p.obs_time,
        p.expiry_time,
        p.forward_rate.start_time,
        p.forward_rate.end_time,
        p.forward_rate.key
    )
    if all(ν² .≤ 0.0)
        # calculate intrinsic value
        return fac .* max.(p.call_put .* (C .- K), 0.0)
    end
    V = black_price(K, C, sqrt.(ν²), p.call_put)
    return fac .* V
end


"""
    string(p::Optionlet)

Formatted (and shortened) output for Optionlet payoff.
"""
string(p::Optionlet) = begin
    type = ""
    if p.call_put == 1.0
        type = "Caplet"
    end
    if p.call_put == -1.0
        type = "Floorlet"
    end
    @sprintf("%s(%s, %s; %.2f)", type, string(p.forward_rate), string(p.strike_rate), p.expiry_time)
end


"""
    struct Swaption <: Payoff
        obs_time::ModelTime
        expiry_time::ModelTime
        settlement_time::ModelTime
        forward_rates::AbstractVector
        fixed_times::AbstractVector
        fixed_weights::AbstractVector
        fixed_rate::ModelValue
        payer_receiver::ModelValue
        disc_key::String
        rate_type::DataType  # to distinguish from functions
    end

Time-t forward price of an option paying An⋅[ϕ(S-K)]^+. Swap rate S is determined at `expiry_time`.
Floating rates in S can be forward looking of backward looking rates.

Forward price is calculated in T-forward measure where T corresponds to `settlement_time`.
Conditioning (for time-t price) is on information at `obs_time`.
"""
struct Swaption <: Payoff
    obs_time::ModelTime
    expiry_time::ModelTime
    settlement_time::ModelTime
    forward_rates::AbstractVector
    fixed_times::AbstractVector
    fixed_weights::AbstractVector
    fixed_rate::ModelValue
    payer_receiver::ModelValue
    disc_key::String
    rate_type::DataType  # to distinguish from functions
end


"""
    Swaption(
        obs_time_::ModelTime,
        expiry_time::ModelTime,
        settlement_time::ModelTime,
        forward_rates::AbstractVector,
        fixed_times::AbstractVector,
        fixed_weights::AbstractVector,
        fixed_rate::ModelValue,
        payer_receiver::ModelValue,
        disc_key::String,
        )

Create a `Swaption` payoff.
"""
function Swaption(
    obs_time_::ModelTime,
    expiry_time::ModelTime,
    settlement_time::ModelTime,
    forward_rates::AbstractVector,
    fixed_times::AbstractVector,
    fixed_weights::AbstractVector,
    fixed_rate::ModelValue,
    payer_receiver::ModelValue,
    disc_key::String,
    )
    #
    @assert obs_time_ ≤ expiry_time
    @assert expiry_time ≤ settlement_time
    @assert length(forward_rates) > 0
    rate_type = typeof(forward_rates[1])
    @assert rate_type in (LiborRate, CompoundedRate)
    rate_key = forward_rates[1].key
    for forward_rate in forward_rates
        @assert typeof(forward_rate) == rate_type
        @assert forward_rate.obs_time == obs_time_
        @assert expiry_time ≤ forward_rate.start_time
        @assert forward_rate.key == rate_key
    end
    @assert length(fixed_weights) > 0
    @assert length(fixed_times) == length(fixed_weights) + 1
    @assert fixed_times[1] == forward_rates[1].start_time
    @assert fixed_times[end] == forward_rates[end].end_time
    @assert payer_receiver in (+1.0, -1.0)
    return Swaption(
        obs_time_,
        expiry_time,
        settlement_time,
        forward_rates,
        fixed_times,
        fixed_weights,
        fixed_rate,
        payer_receiver,
        disc_key,
        rate_type,
    )
end

"""
    obs_time(p::Swaption)

Return Swaption observation time.
"""
function obs_time(p::Swaption)
    return p.obs_time
end


"""
    obs_times(p::Swaption)

Return all Swaption observation times.
"""
function obs_times(p::Swaption)
    times = Set(obs_time(p))
    return times
end


"""
    at(p::Swaption, path::AbstractPath)

Evaluate a `Swaption` at a given `path`, *X(omega)*.
"""
function at(p::Swaption, path::AbstractPath)
    float_leg = sum(((L(path) .* L.year_fraction) .* zero_bond(path, p.obs_time, L.end_time, p.disc_key) for L in p.forward_rates))
    annuity = sum((τ .* zero_bond(path, p.obs_time, T, p.disc_key) for (τ, T) in zip(p.fixed_weights, p.fixed_times[2:end])))
    swap_rate = float_leg ./ annuity
    df = zero_bond(path, p.obs_time, p.settlement_time, p.disc_key)
    ν² = swap_rate_variance(path, p.obs_time, p.expiry_time, p.fixed_times, p.fixed_weights, p.disc_key)
    if all(ν² .≤ 0.0)
        # calculate intrinsic value
        return annuity ./ df .* max.(p.payer_receiver*(swap_rate .- p.fixed_rate), 0.0)
    end
    V = bachelier_price(p.fixed_rate, swap_rate, sqrt.(ν²), p.payer_receiver)
    return annuity ./ df .* V
end


"""
    string(p::Swaption)

Formatted (and shortened) output for Swaption payoff.
"""
string(p::Swaption) = begin
    type = ""
    if p.payer_receiver == +1.0
        type = "Pay"
    end
    if p.payer_receiver == -1.0
        type = "Rec"
    end
    @sprintf("Swaption_%s([%s,...,%s], %.4f, %s; %.2f)",
        type,
        string(p.forward_rates[1]),
        string(p.forward_rates[end]),
        p.fixed_rate,
        p.disc_key,
        p.expiry_time,
    )
end

