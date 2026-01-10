
"""
    struct FlatForward{T<:ModelValue} <: YieldTermstructure
        alias::String
        rate::T
    end

A constant yield term structure.
"""
struct FlatForward{T<:ModelValue} <: YieldTermstructure
    alias::String
    rate::T
end

"""
    flat_forward(alias::String, rate)

Create a FlatForward yield curve.
"""
function flat_forward(alias::String, rate)
    return FlatForward(alias, rate)
end

"""
    flat_forward(rate)

Create a FlatForward yield curve without alias.
"""
function flat_forward(rate)
    return flat_forward("", rate)
end

"""
    discount(ts::FlatForward, t::ModelTime)

Calculate discount factor.
"""
function discount(ts::FlatForward, t::ModelTime)
    return exp(-ts.rate * t)
end


"""
    struct ZeroCurve{T<:ModelValue, InterpolationType} <: YieldTermstructure
        alias::String
        times::Vector{ModelTime}
        values::Vector{T}
        interpolation::InterpolationType
    end

A yield term structure based on interpolated continuous
compounded zero rates.
"""
struct ZeroCurve{T<:ModelValue, InterpolationType} <: YieldTermstructure
    alias::String
    times::Vector{ModelTime}
    values::Vector{T}
    interpolation::InterpolationType
end

"""
    zero_curve(
        alias::String,
        times::AbstractVector,
        values::AbstractVector,
        interp_method = (x,y) -> linear_interpolation(x, y, extrapolation_bc = Line()),
        )

Create a ZeroCurve object.
"""
function zero_curve(
    alias::String,
    times::AbstractVector,
    values::AbstractVector,
    interp_method = (x,y) -> linear_interpolation(x, y, extrapolation_bc = Line()),
    )
    return ZeroCurve(alias, times, values, interp_method(times, values))
end

"""
    zero_curve(
        times::AbstractVector,
        values::AbstractVector,
        interp_method = (x,y) -> linear_interpolation(x, y, extrapolation_bc = Line()),
        )

Create a ZeroCurve object without alias.
"""
function zero_curve(
    times::AbstractVector,
    values::AbstractVector,
    interp_method = (x,y) -> linear_interpolation(x, y, extrapolation_bc = Line()),
    )
    return zero_curve("", times, values, interp_method)
end

"""
    zero_curve(
        alias::String,
        times::AbstractVector,
        values::AbstractVector,
        method_alias::String,
        )

Create a ZeroCurve object using interpolation string.
"""
function zero_curve(
    alias::String,
    times::AbstractVector,
    values::AbstractVector,
    method_alias::String,
    )
    return zero_curve(alias, times, values, interpolation_methods[uppercase(method_alias)])
end

"""
    zero_curve(
        times::AbstractVector,
        values::AbstractVector,
        method_alias::String,
        )

Create a ZeroCurve object using interpolation string.
"""
function zero_curve(
    times::AbstractVector,
    values::AbstractVector,
    method_alias::String,
    )
    return zero_curve("", times, values, method_alias)
end


"""
    discount(ts::ZeroCurve, t::ModelTime)

Calculate discount factor.
"""
function discount(ts::ZeroCurve, t::ModelTime)
    z = ts.interpolation(t)
    return exp(-z * t)
end


"""
    struct LinearZeroCurve{T<:ModelValue} <: YieldTermstructure
        alias::String
        times::Vector{ModelTime}
        values::Vector{T}
    end

A yield term structure based on continuous compounded zero rates
with linear interpolation and flat extrapolation.

This curve aims at mitigating limitations of Zygote and ZeroCurve.
"""
struct LinearZeroCurve{T<:ModelValue} <: YieldTermstructure
    alias::String
    times::Vector{ModelTime}
    values::Vector{T}
end


"""
    linear_zero_curve(
        alias::String,
        times::AbstractVector,
        values::AbstractVector,
        )

Create a LinearZeroCurve.
"""
function linear_zero_curve(
    alias::String,
    times::AbstractVector,
    values::AbstractVector,
    )
    return LinearZeroCurve(alias, times, values)
end


"""
    linear_zero_curve(
        times::AbstractVector,
        values::AbstractVector,
        )

Create a LinearZeroCurve with empty alias.
"""
function linear_zero_curve(
    times::AbstractVector,
    values::AbstractVector,
    )
    return linear_zero_curve("", times, values)
end


"""
    _interpolate(ts::LinearZeroCurve, t::ModelTime)

Linear interpolation with flat exrapolation.
"""
function _interpolate(ts::LinearZeroCurve, t::ModelTime)
    idx = searchsortedfirst(ts.times, t)
     # left flat extrapolation
    if idx == 1
        return ts.values[idx]
    end
    # right flat extrapolation
    if idx > length(ts.times)
        return ts.values[idx-1]
    end
    # linear interpolation
    rho = (t - ts.times[idx-1]) / ((ts.times[idx] - ts.times[idx-1]))
    return rho * ts.values[idx] + (1.0 - rho) * ts.values[idx-1]
end


"""
    discount(ts::LinearZeroCurve, t::ModelTime)

Calculate discount factor.
"""
function discount(ts::LinearZeroCurve, t::ModelTime)
    z = _interpolate(ts, t)
    return exp(-z * t)
end
