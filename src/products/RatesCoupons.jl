
"""
    struct FixedRateCoupon <: Coupon
        pay_time::ModelTime
        fixed_rate::ModelValue
        year_fraction::ModelValue
    end

A fixed rate coupon.
"""
struct FixedRateCoupon <: Coupon
    pay_time::ModelTime
    fixed_rate::ModelValue
    year_fraction::ModelValue
    first_time::Union{ModelTime,Nothing}
end


function FixedRateCoupon(
    pay_time::ModelTime,
    fixed_rate::ModelValue,
    year_fraction::ModelValue,
    )
    return FixedRateCoupon(
        pay_time,
        fixed_rate,
        year_fraction,
        nothing,
    )
end


"""
    year_fraction(cf::FixedRateCoupon)

Return FixedRateCoupon year_fraction.
"""
year_fraction(cf::FixedRateCoupon) = cf.year_fraction

"""
    coupon_rate(cf::FixedRateCoupon)

Return FixedRateCoupon rate.
"""
coupon_rate(cf::FixedRateCoupon) = Fixed(cf.fixed_rate)

"""
    forward_rate(cf::FixedRateCoupon, obs_time::ModelTime)

Return FixedRateCoupon forward rate.
"""
forward_rate(cf::FixedRateCoupon, obs_time::ModelTime) = Fixed(cf.fixed_rate)


"""
    first_time(cf::FixedRateCoupon)

Derive the first event time of the `FixedRateCoupon`.
"""
function first_time(cf::FixedRateCoupon)
    if isnothing(cf.first_time)
        error("FixedRateCoupon has no specified first_time.")
    end
    return cf.first_time
end


"""
    struct SimpleRateCoupon <: Coupon
        fixing_time::ModelTime
        start_time::ModelTime
        end_time::ModelTime
        pay_time::ModelTime
        year_fraction::ModelValue
        curve_key::String
        fixing_key::Union{String, Nothing}
        spread_rate::Union{ModelValue, Nothing}
    end

A (legacy) Libor or Euribor rate coupon.
"""
struct SimpleRateCoupon <: Coupon
    fixing_time::ModelTime
    start_time::ModelTime
    end_time::ModelTime
    pay_time::ModelTime
    year_fraction::ModelValue
    curve_key::String
    fixing_key::Union{String, Nothing}
    spread_rate::Union{ModelValue, Nothing}
end

"""
    year_fraction(cf::SimpleRateCoupon)

Return SimpleRateCoupon year_fraction.
"""
year_fraction(cf::SimpleRateCoupon) = cf.year_fraction

"""
    coupon_rate(cf::SimpleRateCoupon)

Return SimpleRateCoupon rate.
"""
function coupon_rate(cf::SimpleRateCoupon)
    if cf.fixing_time < 0.0
        @assert !isnothing(cf.fixing_key)
        L = Fixing(cf.fixing_time, cf.fixing_key)
    else
        L = LiborRate(cf.fixing_time, cf.start_time, cf.end_time, cf.curve_key)
    end
    if !isnothing(cf.spread_rate)
        L = L + cf.spread_rate
    end
    return L
end

"""
    forward_rate(cf::SimpleRateCoupon, obs_time::ModelTime)

Return SimpleRateCoupon forward rate.
"""
function forward_rate(cf::SimpleRateCoupon, obs_time::ModelTime)
    @assert obs_time >= 0.0
    if obs_time >= cf.fixing_time
        return coupon_rate(cf)
    end
    # calculate forward rate
    L = LiborRate(obs_time, cf.start_time, cf.end_time, cf.curve_key)
    if !isnothing(cf.spread_rate)
        L = L + cf.spread_rate
    end
    return L
end


"""
    first_time(cf::SimpleRateCoupon)

Derive the first event time of the `SimpleRateCoupon`.
"""
function first_time(cf::SimpleRateCoupon)
    return cf.fixing_time
end


"""
    struct CompoundedRateCoupon <: Coupon
        period_times::AbstractVector
        period_year_fractions::AbstractVector
        pay_time::ModelTime
        curve_key::String
        fixing_key::Union{String, Nothing}
        spread_rate::Union{ModelValue, Nothing}
    end

A backward-looking compounded RFR coupon.
"""
struct CompoundedRateCoupon <: Coupon
    period_times::AbstractVector
    period_year_fractions::AbstractVector
    pay_time::ModelTime
    curve_key::String
    fixing_key::Union{String, Nothing}
    spread_rate::Union{ModelValue, Nothing}
end

"""
    year_fraction(cf::CompoundedRateCoupon)

Return CompoundedRateCoupon year_fraction.
"""
year_fraction(cf::CompoundedRateCoupon) = sum(cf.period_year_fractions)


"""
    coupon_rate(cf::CompoundedRateCoupon)

Return CompoundedRateCoupon rate.
"""
function coupon_rate(cf::CompoundedRateCoupon)
    @assert length(cf.period_times) >= 2
    @assert length(cf.period_times) == length(cf.period_year_fractions) + 1
    C = nothing  # no fixings
    start_time = 0.0
    if cf.period_times[1] < 0.0  # assume period_times sorted
        @assert !isnothing(cf.fixing_key)
        C = 1 + Fixing(cf.period_times[1], cf.fixing_key) * cf.period_year_fractions[1]
        k = 2
        while (k <= length(cf.period_times) - 1) && (cf.period_times[k] < 0.0)
            C = C * (1 + Fixing(cf.period_times[k], cf.fixing_key) * cf.period_year_fractions[k])
            k += 1
        end
        if k == length(cf.period_times)
            # rate is completely fixed and we take a short-cut here
            R = (C - 1.0) / year_fraction(cf)
            if !isnothing(cf.spread_rate)
                R = R + cf.spread_rate
            end
            return R
        end
        # cf.period_times[k] >= 0.0
        start_time = cf.period_times[k]
    end
    R = CompoundedRate(
        cf.period_times[end],
        max(start_time, cf.period_times[begin]),
        cf.period_times[end],
        year_fraction(cf),
        cf.curve_key,
        C,
    )
    if !isnothing(cf.spread_rate)
        R = R + cf.spread_rate
    end
    return R
end


"""
    forward_rate(cf::CompoundedRateCoupon, obs_time::ModelTime)

Return CompoundedRateCoupon forward rate.
"""
function forward_rate(cf::CompoundedRateCoupon, obs_time::ModelTime)
    @assert length(cf.period_times) >= 2
    @assert length(cf.period_times) == length(cf.period_year_fractions) + 1
    @assert obs_time >= 0.0
    C = nothing  # no fixings
    start_time = 0.0
    if cf.period_times[1] < 0.0  # assume period_times sorted
        # this case needs manual treatment
        @assert !isnothing(cf.fixing_key)
        C = 1 + Fixing(cf.period_times[1], cf.fixing_key) * cf.period_year_fractions[1]
        k = 2
        while (k <= length(cf.period_times) - 1) && (cf.period_times[k] < 0.0)
            C = C * (1 + Fixing(cf.period_times[k], cf.fixing_key) * cf.period_year_fractions[k])
            k += 1
        end
        if k == length(cf.period_times)
            # rate is completely fixed and we take a short-cut here
            R = (C - 1.0) / year_fraction(cf)
            if !isnothing(cf.spread_rate)
                R = R + cf.spread_rate
            end
            return R
        end
        # cf.period_times[k] >= 0.0
        start_time = cf.period_times[k]
    end
    # println(string(C))
    R = CompoundedRate(
        obs_time,
        max(start_time, cf.period_times[begin]),
        cf.period_times[end],
        year_fraction(cf),
        cf.curve_key,
        C,
    )
    if !isnothing(cf.spread_rate)
        R = R + cf.spread_rate
    end
    return R
end


"""
    first_time(cf::CompoundedRateCoupon)

Derive the first event time of the `CompoundedRateCoupon`.
"""
function first_time(cf::CompoundedRateCoupon)
    return cf.period_times[begin]
end


"""
    struct OptionletCoupon <: Coupon
        expiry_time::ModelTime
        coupon::Union{SimpleRateCoupon, CompoundedRateCoupon}
        strike_rate::ModelValue
        call_put::ModelValue
        coupon_type::DataType  # distinguish constructors
    end

A caplet or floorlet coupon on a forward-looking or backward-looking rate.
"""
struct OptionletCoupon <: Coupon
    expiry_time::ModelTime
    coupon::Union{SimpleRateCoupon, CompoundedRateCoupon}
    strike_rate::ModelValue
    call_put::ModelValue
    coupon_type::DataType  # distinguish constructors
end

"""
    OptionletCoupon(
        expiry_time::ModelTime,
        coupon::Union{SimpleRateCoupon, CompoundedRateCoupon},
        strike_rate::ModelValue,
        call_put::ModelValue,
        )

Create an `OptionletCoupon` object from an underlying `SimpleRateCoupon` or
`CompoundedRateCoupon`.

Option `expiry_time` is specified by user.
"""
function OptionletCoupon(
    expiry_time::ModelTime,
    coupon::Union{SimpleRateCoupon, CompoundedRateCoupon},
    strike_rate::ModelValue,
    call_put::ModelValue,
    )
    #
    @assert isnothing(coupon.spread_rate)
    @assert (typeof(coupon) != SimpleRateCoupon) || (expiry_time ≤ coupon.start_time)
    @assert (typeof(coupon) != CompoundedRateCoupon) || (expiry_time == coupon.period_times[end])
    @assert call_put in (+1.0, -1.0)
    return OptionletCoupon(expiry_time, coupon, strike_rate, call_put, typeof(coupon))
end

"""
    OptionletCoupon(
        expiry_time::ModelTime,
        coupon::Union{SimpleRateCoupon, CompoundedRateCoupon},
        strike_rate::ModelValue,
        call_put::ModelValue,
        )

Create an `OptionletCoupon` object from an underlying `SimpleRateCoupon` or
`CompoundedRateCoupon`.

Option `expiry_time` is determined from underlying coupon.
"""
function OptionletCoupon(
    coupon::Union{SimpleRateCoupon, CompoundedRateCoupon},
    strike_rate::ModelValue,
    call_put::ModelValue,
    )
    #
    if typeof(coupon) == SimpleRateCoupon
        expiry_time = coupon.fixing_time
    end
    if typeof(coupon) == CompoundedRateCoupon
        expiry_time = coupon.period_times[end]
    end
    return OptionletCoupon(expiry_time, coupon, strike_rate, call_put)
end


"""
    pay_time(cf::OptionletCoupon)

Return the payment time for a OptionletCoupon.

This coincides with the payment time of the underlying coupon.
"""
pay_time(cf::OptionletCoupon) = pay_time(cf.coupon)


"""
    year_fraction(cf::OptionletCoupon)

Return OptionletCoupon year_fraction.
"""
year_fraction(cf::OptionletCoupon) = year_fraction(cf.coupon)


"""
    coupon_rate(cf::OptionletCoupon)

Return OptionletCoupon rate.
"""
function coupon_rate(cf::OptionletCoupon)
    R = coupon_rate(cf.coupon)
    return Max(cf.call_put*(R - cf.strike_rate), 0.0)
end


"""
    forward_rate(cf::OptionletCoupon, obs_time::ModelTime)

Return OptionletCoupon forward rate.
"""
function forward_rate(cf::OptionletCoupon, obs_time::ModelTime)
    if (typeof(cf.coupon) == SimpleRateCoupon) && (obs_time ≥ cf.expiry_time)
        return coupon_rate(cf)
    end
    if (typeof(cf.coupon) == CompoundedRateCoupon) && (obs_time ≥ cf.coupon.period_times[end])
        return coupon_rate(cf)
    end
    if (typeof(cf.coupon) == CompoundedRateCoupon) &&
       (obs_time ≥ cf.coupon.period_times[end-1]) &&
       (cf.coupon.period_times[end-1] < 0.0)
        # this case is a bit tricky...
        # with this methodology we may look a day (period) into the future
        # this is a model limitation of the continuous rate approximation
        return coupon_rate(cf)
    end
    R = forward_rate(cf.coupon, obs_time)
    K = Fixed(cf.strike_rate)
    return Optionlet(obs_time, cf.expiry_time, R, K, cf.call_put)
end
