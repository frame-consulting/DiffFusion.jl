
"""
    struct VanillaAssetOption <: Payoff
        obs_time::ModelTime
        expiry_time::ModelTime
        forward_price::ForwardAsset
        strike_price::Payoff
        call_put::ModelValue
    end

The time-t forward price of an option paying [ϕ(F-K)]^+. Forward asset price *F* is determined
at `expiry_time`.

Option forward price is calculated as expectation in T-forward measure where T corresponds
to the expiry time. Conditioning (for time-t price) is on information at `obs_time`.

Strike price `strike_price` must be time-t (`obs_time`) measurable. Otherwise, we *look into
the future*.
"""
struct VanillaAssetOption <: Payoff
    obs_time::ModelTime
    expiry_time::ModelTime
    forward_price::ForwardAsset
    strike_price::Payoff
    call_put::ModelValue
end

"""
    VanillaAssetOption(
        forward_price::ForwardAsset,
        strike_price::Payoff,
        call_put::ModelValue,
        )

Create a `VanillaAssetOption` payoff.
"""
function VanillaAssetOption(
    forward_price::ForwardAsset,
    strike_price::Payoff,
    call_put::ModelValue,
    )
    #
    @assert obs_time(strike_price) ≤ forward_price.obs_time  # payoff must be time-t measurable
    @assert call_put in (+1.0, -1.0)
    return VanillaAssetOption(
        forward_price.obs_time,
        forward_price.maturity_time,
        forward_price,
        strike_price,
        call_put,
    )
end


"""
    obs_time(p::VanillaAssetOption)

Return VanillaAssetOption observation time.
"""
function obs_time(p::VanillaAssetOption)
    return p.obs_time
end


"""
    obs_times(p::VanillaAssetOption)

Return all VanillaAssetOption observation times. 
"""
function obs_times(p::VanillaAssetOption)
    times = Set(obs_time(p))
    times = union(times, obs_times(p.strike_price))
    return times
end


"""
    at(p::VanillaAssetOption, path::AbstractPath)

Evaluate a `VanillaAssetOption` at a given `path`, *X(omega)*.
"""
function at(p::VanillaAssetOption, path::AbstractPath)
    F = at(p.forward_price, path)
    K = at(p.strike_price, path)
    ν² = asset_variance(path, p.obs_time, p.expiry_time, p.forward_price.key)
    if all(ν² .≤ 0.0)
        # calculate intrinsic value
        return max.(p.call_put*(F - K), 0.0)
    end
    V = black_price(K, F, sqrt.(ν²), p.call_put)
    return V
end


"""
    string(p::VanillaAssetOption)

Formatted (and shortened) output for VanillaAssetOption payoff.
"""
string(p::VanillaAssetOption) = begin
    type = ""
    if p.call_put == 1.0
        type = "Call"
    end
    if p.call_put == -1.0
        type = "Put"
    end
    @sprintf("%s(%s, %s)", type, string(p.forward_price), string(p.strike_price))
end
