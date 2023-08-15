
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
