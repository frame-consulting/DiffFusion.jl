

"""
    struct RelativeReturnCoupon <: Coupon
        first_time::ModelTime
        second_time::ModelTime
        pay_time::ModelTime
        year_fraction::ModelValue
        asset_key::String
        curve_key_dom::String
        curve_key_for::String
    end

A `RelativeReturnCoupon` pays a coupon with rate (S2/S1 - 1) / dT. Here,
S1 and S2 are spot asset prices.

Such a coupon is typical for year-on-year type instruments.
"""
struct RelativeReturnCoupon <: Coupon
    first_time::ModelTime
    second_time::ModelTime
    pay_time::ModelTime
    year_fraction::ModelValue
    asset_key::String
    curve_key_dom::String
    curve_key_for::String
end

"""
    year_fraction(cf::RelativeReturnCoupon)

Return RelativeReturnCoupon year_fraction.
"""
year_fraction(cf::RelativeReturnCoupon) = cf.year_fraction

"""
    coupon_rate(cf::RelativeReturnCoupon)

Return RelativeReturnCoupon rate.
"""
function coupon_rate(cf::RelativeReturnCoupon)
    S1 = Asset(cf.first_time, cf.asset_key)
    S2 = Asset(cf.second_time, cf.asset_key)
    return (S2 / S1 - 1.0) / cf.year_fraction
end

"""
    forward_rate(cf::RelativeReturnCoupon, obs_time::ModelTime)

Return RelativeReturnCoupon forward rate.
"""
function forward_rate(cf::RelativeReturnCoupon, obs_time::ModelTime)
    S1 = Asset(min(obs_time, cf.first_time), cf.asset_key)
    if obs_time < cf.first_time
        df_dom = ZeroBond(obs_time, cf.first_time, cf.curve_key_dom)
        df_for = ZeroBond(obs_time, cf.first_time, cf.curve_key_for)
        S1 = S1 * df_for / df_dom
    end
    S2 = Asset(min(obs_time, cf.second_time), cf.asset_key)
    if obs_time < cf.second_time
        df_dom = ZeroBond(obs_time, cf.second_time, cf.curve_key_dom)
        df_for = ZeroBond(obs_time, cf.second_time, cf.curve_key_for)
        S2 = S2 * df_for / df_dom
    end
    S2_over_S1 = S2 / S1
    CA = nothing
    if (obs_time < cf.second_time) && (cf.first_time < cf.second_time)
        if obs_time < cf.first_time
            # full YoY CA
            CA = AssetConvexityAdjustment(obs_time, cf.first_time, cf.second_time, cf.pay_time, cf.asset_key)
        else
            if cf.second_time < cf.pay_time
                # payment delay CA
                CA = AssetConvexityAdjustment(obs_time, obs_time, cf.second_time, cf.pay_time, cf.asset_key)
            end    
        end
    end
    if !isnothing(CA)
        S2_over_S1 = S2_over_S1 * CA
    end
    return (S2_over_S1 - 1.0) / cf.year_fraction
end

