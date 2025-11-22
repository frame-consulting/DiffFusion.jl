
"""
    struct FlatSpreadCurve <: CreditDefaultTermstructure
        alias::String
        spread::ModelValue
    end

A flat credit spread curve.
"""
struct FlatSpreadCurve <: CreditDefaultTermstructure
    alias::String
    spread::ModelValue
end

"""
    flat_spread_curve(alias::String, spread::ModelValue)

Create a FlatSpreadCurve.
"""
function flat_spread_curve(alias::String, spread::ModelValue)
    return FlatSpreadCurve(alias, spread)
end


"""
    flat_spread_curve(spread::ModelValue)

Create a FlatSpreadCurve without alias.
"""
function flat_spread_curve(spread::ModelValue)
    return FlatSpreadCurve("", spread)
end


"""
    survival(ts::FlatSpreadCurve, t::ModelTime)

Calculate survival probability.
"""
survival(ts::FlatSpreadCurve, t::ModelTime) = exp(-ts.spread * t)



"""
    struct LogSurvivalCurve <: CreditDefaultTermstructure
        alias::String
        times::AbstractVector
        values::AbstractVector
    end

Log-interpolated survival probabilities.
"""
struct LogSurvivalCurve <: CreditDefaultTermstructure
    alias::String
    times::AbstractVector
    values::AbstractVector
    interpolation
end


"""
    survival_curve(
        alias::String,
        times::AbstractVector,
        survival_probs::AbstractVector,
        interp_method = (x,y) -> linear_interpolation(x, y, extrapolation_bc = Line()),
        )

Create a LogSurvivalCurve.
"""
function survival_curve(
    alias::String,
    times::AbstractVector,
    survival_probs::AbstractVector,
    interp_method = (x,y) -> linear_interpolation(x, y, extrapolation_bc = Line()),
    )
    @assert length(times) > 0
    @assert length(times) == length(survival_probs)
    if times[begin] != 0.0
        non_differentiable_warn("First time should typically be 0.0.", times[begin])
    end
    if survival_probs[begin] != 1.0
        non_differentiable_warn("First survival probability should typically be 1.0.", survival_probs[begin])
    end
    values = log.(survival_probs)
    return LogSurvivalCurve(alias, times, values, interp_method(times, values))
end


"""
    survival_curve(
        alias::String,
        times::AbstractVector,
        survival_probs::AbstractVector,
        method_alias::String,
        )

Create a LogSurvivalCurve for pre-defined interpolation methods.
"""
function survival_curve(
    alias::String,
    times::AbstractVector,
    survival_probs::AbstractVector,
    method_alias::String,
    )
    return survival_curve(alias, times, survival_probs, interpolation_methods[uppercase(method_alias)])
end


"""
    survival(ts::LogSurvivalCurve, t::ModelTime)

Calculate survival probability.
"""
survival(ts::LogSurvivalCurve, t::ModelTime) = exp(ts.interpolation(t))
