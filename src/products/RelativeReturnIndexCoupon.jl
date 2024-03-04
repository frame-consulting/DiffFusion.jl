
"""
    struct RelativeReturnIndexCoupon <: Coupon
        first_time::ModelTime
        second_time::ModelTime
        pay_time::ModelTime
        year_fraction::ModelValue
        forward_index_key::String
    end

A `RelativeReturnIndexCoupon` pays a coupon with rate (I2/I1 - 1) / dT. Here,
I1 and I2 are spot (index) prices for which a forward index curve is available.

Such a coupon is typical for year-on-year type instruments.
"""
struct RelativeReturnIndexCoupon <: Coupon
    first_time::ModelTime
    second_time::ModelTime
    pay_time::ModelTime
    year_fraction::ModelValue
    forward_index_key::String
end

"""
    year_fraction(cf::RelativeReturnIndexCoupon)

Return RelativeReturnIndexCoupon year_fraction.
"""
year_fraction(cf::RelativeReturnIndexCoupon) = cf.year_fraction

"""
    coupon_rate(cf::RelativeReturnIndexCoupon)

Return RelativeReturnIndexCoupon rate.
"""
function coupon_rate(cf::RelativeReturnIndexCoupon)
    I1 = ForwardIndex(cf.first_time, cf.first_time, cf.forward_index_key)
    I2 = ForwardIndex(cf.second_time, cf.second_time, cf.forward_index_key)
    return (I2 / I1 - 1.0) / cf.year_fraction
end

"""
    forward_rate(cf::RelativeReturnIndexCoupon, obs_time::ModelTime)

Return RelativeReturnIndexCoupon forward rate.
"""
function forward_rate(cf::RelativeReturnIndexCoupon, obs_time::ModelTime)
    I1 = ForwardIndex(min(obs_time, cf.first_time), cf.first_time, cf.forward_index_key)
    I2 = ForwardIndex(min(obs_time, cf.second_time), cf.second_time, cf.forward_index_key)
    I2_over_I1 = I2 / I1
    CA = nothing
    if (obs_time < cf.second_time) && (cf.first_time < cf.second_time)
        if obs_time < cf.first_time
            # full YoY CA
            CA = IndexConvexityAdjustment(obs_time, cf.first_time, cf.second_time, cf.pay_time, cf.forward_index_key)
        else
            if cf.second_time < cf.pay_time
                # payment delay CA
                CA = IndexConvexityAdjustment(obs_time, obs_time, cf.second_time, cf.pay_time, cf.forward_index_key)
            end    
        end
    end
    if !isnothing(CA)
        I2_over_I1 = I2_over_I1 * CA
    end
    return (I2_over_I1 - 1.0) / cf.year_fraction
end

