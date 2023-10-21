

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
    C = 1.0 .+ τ * at(p.forward_rate, path)
    K = (1.0 .+ τ * at(p.strike_rate, path)) ./ at(p.gearing_factor, path)
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
        return fac .* max.(p.call_put*(C - K), 0.0)
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

