
"""
    struct BarrierAssetOption <: Payoff
        obs_time::ModelTime
        expiry_time::ModelTime
        forward_price::ForwardAsset
        strike_price::Payoff
        call_put::ModelValue
        barrier_level::Payoff
        barrier_direction::ModelValue
        barrier_type::ModelValue
        rebate_price::ModelValue
        no_hit_times::AbstractVector
    end

The time-t forward price of an option paying [ϕ(F-K)]^+. Forward asset price *F* is determined
at `expiry_time`.

Option forward price is calculated as expectation in T-forward measure where T corresponds
to the expiry time. Conditioning (for time-t price) is on information at `obs_time`. This
requires particular care when using Black-Scholes pricing functions.

Strike price `strike_price` and barrier level `barrier_level` must be time-t (`obs_time`)
measurable. Otherwise, we *look into the future*.

`barrier_direction` is -1 for up-barrier and +1 for down-barrier. `barrier_type` is -1 for
in-barrier and +1 for out-barrier. See also `black_scholes_barrier_price`.

`no_hit_times` is a list of times where past hit events are observed and with which
no-hit probability is estimated. First time is zero and last time is `obs_time`. Must be
of length 2 or more.
"""
struct BarrierAssetOption <: Payoff
    obs_time::ModelTime
    expiry_time::ModelTime
    forward_price::ForwardAsset
    strike_price::Payoff
    call_put::ModelValue
    barrier_level::Payoff
    barrier_direction::ModelValue
    barrier_type::ModelValue
    rebate_price::ModelValue
    no_hit_times::AbstractVector
end


"""
    BarrierAssetOption(
        forward_price::ForwardAsset,
        strike_price::Payoff,
        barrier_level::Payoff,
        option_type::String,
        rebate_price::ModelValue,
        number_of_no_hit_times::Integer,
        )

Create a `BarrierAssetOption` payoff.

String `option_type` is of the form [D|U][O|I][C|P].

No-hit times are calculates as equally spaced times of
length `number_of_no_hit_times`.
"""
function BarrierAssetOption(
    forward_price::ForwardAsset,
    strike_price::Payoff,
    barrier_level::Payoff,
    option_type::String,
    rebate_price::ModelValue,
    number_of_no_hit_times::Integer,
    )
    #
    @assert obs_time(strike_price) ≤ forward_price.obs_time  # payoff must be time-t measurable
    @assert length(option_type) == 3
    @assert number_of_no_hit_times ≥ 2
    # derive option properties
    o_type = uppercase(option_type)
    @assert o_type[1] in ('D', 'U')
    @assert o_type[2] in ('O', 'I')
    @assert o_type[3] in ('C', 'P')
    if o_type[1] == 'D'
        η = 1
    else
        η = -1
    end
    if o_type[2] == 'O'
        χ = 1
    else
        χ = -1
    end
    if o_type[3] == 'C'
        ϕ = 1
    else
        ϕ = -1
    end
    #
    no_hit_times = LinRange(0.0, forward_price.obs_time, number_of_no_hit_times)
    #
    return BarrierAssetOption(
        forward_price.obs_time,
        forward_price.maturity_time,
        forward_price,
        strike_price,
        ϕ,
        barrier_level,
        η,
        χ,
        rebate_price,
        no_hit_times,
    )
end


"""
    obs_time(p::BarrierAssetOption)

Return BarrierAssetOption observation time.
"""
function obs_time(p::BarrierAssetOption)
    return p.obs_time
end


"""
    obs_times(p::BarrierAssetOption)

Return all BarrierAssetOption observation times. 
"""
function obs_times(p::BarrierAssetOption)
    times = Set(obs_time(p))
    times = union(times, obs_times(p.strike_price))
    times = union(times, p.no_hit_times)
    return times
end


"""
    at(p::BarrierAssetOption, path::AbstractPath)

Evaluate a `BarrierAssetOption` at a given `path`, *X(omega)*.
"""
function at(p::BarrierAssetOption, path::AbstractPath)
    # F = at(p.forward_price, path)
    (S, Pd, Pf) = forward_asset_and_zero_bonds(
        path,
        p.forward_price.obs_time,
        p.forward_price.maturity_time,
        p.forward_price.key
    )
    F = S .* Pf ./ Pd
    #
    K = p.strike_price(path)
    H = p.barrier_level(path)
    ν² = asset_variance(path, p.obs_time, p.expiry_time, p.forward_price.key)
    T = p.expiry_time - p.obs_time
    σ = 0.0
    if T > 0.0
        σ = sqrt.(ν² / T)
    end
    # calculate hit-price
    if p.barrier_type == 1  # out-Barrier
        hit_price = p.rebate_price
    else
        # Vanilla option price
        if all(ν² .≤ 0.0)
            # calculate intrinsic value
            hit_price = max.(p.call_put*(F - K), 0.0)
        else
            hit_price = black_price(K, F, sqrt.(ν²), p.call_put)
        end
    end
    # calculate no-hit price
    #
    σ = max.(σ, 0.001)  # we need a positive volatility
    T = max(T, 1.0/365/24) # we approximate intrinsic value by option value 1h prior to exercise

    no_hit_price = black_scholes_barrier_price(
        K,
        H,
        p.rebate_price,
        p.barrier_direction,
        p.barrier_type,
        p.call_put,
        S, Pd, Pd ./ Pf, σ, T
    ) ./ Pd  # we want the forward price here
    # calculate no hit on path
    #
    S = hcat(
        [ asset(path, t, p.forward_price.key) for t in p.no_hit_times]...
    )
    logS = log.(S)
    logS_returns = logS[:,2:end] .- logS[:,1:end-1]
    variances = std(logS_returns, dims=1).^2
    no_hit_prob = barrier_no_hit_probability(
        log.(H),
        p.barrier_direction,
        logS,
        variances,
    )
    #
    return no_hit_prob .* no_hit_price .+ (1.0 .- no_hit_prob) .* hit_price
end


"""
    string(p::VanillaAssetOption)

Formatted (and shortened) output for VanillaAssetOption payoff.
"""
string(p::BarrierAssetOption) = begin
    option_type = ""
    if p.barrier_direction == -1
        option_type = "U"
    end
    if p.barrier_direction == +1
        option_type = "D"
    end
    if p.barrier_type == -1
        option_type = option_type * "I"
    end
    if p.barrier_type == +1
        option_type = option_type * "O"
    end
    if p.call_put == 1.0
        option_type = option_type * "Call"
    end
    if p.call_put == -1.0
        option_type = option_type * "Put"
    end
    @sprintf("%s(%s, X = %s, H = %s)", option_type, string(p.forward_price), string(p.strike_price), string(p.barrier_level))
end
