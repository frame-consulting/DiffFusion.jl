
"""
    struct FlatForward <: YieldTermstructure
        alias::String
        rate
    end

A constant yield term structure.
"""
struct FlatForward <: YieldTermstructure
    alias::String
    rate
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
    struct ZeroCurve <: YieldTermstructure
        alias::String
        times::AbstractVector
        values::AbstractVector
        interpolation
    end

A yield term structure based on interpolated continuous
compounded zero rates.
"""
struct ZeroCurve <: YieldTermstructure
    alias::String
    times::AbstractVector
    values::AbstractVector
    interpolation
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
    return zero_curve("", times, values, interpolation_methods[uppercase(method_alias)])
end


"""
    discount(ts::ZeroCurve, t::ModelTime)

Calculate discount factor.
"""
function discount(ts::ZeroCurve, t::ModelTime)
    z = ts.interpolation(t)
    return exp(-z * t)
end
