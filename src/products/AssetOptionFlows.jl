
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

This implementation is an approximation and does not capture convexity adjustments.
"""
function expected_amount(cf::VanillaAssetOptionFlow, obs_time::ModelTime)
    if obs_time ≥ cf.expiry_time
        return amount(cf)
    end
    F = ForwardAsset(obs_time, cf.expiry_time, cf.asset_key)
    K = Fixed(cf.strike_price)
    return VanillaAssetOption(F, K, cf.call_put)
end

