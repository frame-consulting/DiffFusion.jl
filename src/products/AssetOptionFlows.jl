
"""
    struct VanillaAssetOptionFlow <: CashFlow
        expiry_time::ModelTime
        pay_time::ModelTime
        strike_price::ModelValue
        call_put::ModelValue
        asset_key::String
    end

A `CashFlow` representing a Call or Put option on an `Asset`.
"""
struct VanillaAssetOptionFlow <: CashFlow
    expiry_time::ModelTime
    pay_time::ModelTime
    strike_price::ModelValue
    call_put::ModelValue
    asset_key::String
end


"""
    amount(cf::VanillaAssetOptionFlow)

Return the payoff of the `VanillaAssetOptionFlow`.
"""
function amount(cf::VanillaAssetOptionFlow)
    S = Asset(cf.expiry_time, cf.asset_key)
    return Max(cf.call_put*(S - cf.strike_price), 0.0)
end


"""
    expected_amount(cf::VanillaAssetOptionFlow, obs_time::ModelTime)

Return the payoff representing the simulated expected amount of the `VanillaAssetOptionFlow`.

This implementation is an approximation and does not capture payment delay convexity adjustments.
"""
function expected_amount(cf::VanillaAssetOptionFlow, obs_time::ModelTime)
    if obs_time ≥ cf.expiry_time
        return amount(cf)
    end
    F = ForwardAsset(obs_time, cf.expiry_time, cf.asset_key)
    K = Fixed(cf.strike_price)
    return VanillaAssetOption(F, K, cf.call_put)
end


"""
    struct BarrierAssetOptionFlow <: CashFlow
        expiry_time::ModelTime
        pay_time::ModelTime
        strike_price::ModelValue
        barrier_level::ModelValue
        rebate_price::ModelValue
        option_type::String
        asset_key::String
        hit_obs_step_size::ModelTime
    end

A `CashFlow` representing a Single Barrier option on an `Asset`.

`option_type` is of the form [D|U][O|I][C|P].

`hit_obs_step_size` represents a modelling parameter to build
the grid of *past* observation times to monitor barrier hit
along the path.
"""
struct BarrierAssetOptionFlow <: CashFlow
    expiry_time::ModelTime
    pay_time::ModelTime
    strike_price::ModelValue
    barrier_level::ModelValue
    rebate_price::ModelValue
    option_type::String
    asset_key::String
    hit_obs_step_size::ModelTime
end


"""
    amount(cf::BarrierAssetOptionFlow)

Return the payoff of the `BarrierAssetOptionFlow`.
"""
function amount(cf::BarrierAssetOptionFlow)
    F = ForwardAsset(cf.expiry_time, cf.expiry_time, cf.asset_key)
    X = Fixed(cf.strike_price)
    H = Fixed(cf.barrier_level)
    nnht = max(2, Int(round(cf.expiry_time / cf.hit_obs_step_size)))
    return BarrierAssetOption(F, X, H, cf.option_type, cf.rebate_price, nnht)
end


"""
    expected_amount(cf::BarrierAssetOptionFlow, obs_time::ModelTime)

Return the payoff representing the simulated expected amount of the `BarrierAssetOptionFlow`.

This implementation is an approximation and does not capture payment delay convexity adjustments.
"""
function expected_amount(cf::BarrierAssetOptionFlow, obs_time::ModelTime)
    if obs_time ≥ cf.expiry_time
        return amount(cf)
    end
    F = ForwardAsset(obs_time, cf.expiry_time, cf.asset_key)
    X = Fixed(cf.strike_price)
    H = Fixed(cf.barrier_level)
    nnht = max(2, Int(round(obs_time / cf.hit_obs_step_size)))
    return BarrierAssetOption(F, X, H, cf.option_type, cf.rebate_price, nnht)
end

