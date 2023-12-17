
"""
    serialise(o::FlatForward)

Serialise FlatForward.
"""
serialise(o::FlatForward) = serialise_struct(o)

"""
    serialise(o::ZeroCurve)

Serialise ZeroCurve.
"""
function serialise(o::ZeroCurve)
    d = OrderedDict{String, Any}()
    d["typename"]    = string(typeof(o))
    d["constructor"] = "zero_curve"
    d["alias"]       = serialise(o.alias)
    d["times"]       = serialise(o.times)
    d["values"]      = serialise(o.values)
    return d
end

"""
    serialise(o::LinearZeroCurve)

    Serialise LinearZeroCurve.
"""
serialise(o::LinearZeroCurve) = serialise_struct(o)

"""
    serialise(o::BackwardFlatVolatility)

Serialise BackwardFlatVolatility.
"""
serialise(o::BackwardFlatVolatility) = serialise_struct(o)

"""
    serialise(o::PiecewiseFlatParameter)

Serialise PiecewiseFlatParameter.
"""
serialise(o::PiecewiseFlatParameter) = serialise_struct(o)

"""
    serialise(o::CorrelationHolder)

Serialise CorrelationHolder.
"""
function serialise(o::CorrelationHolder)
    d = OrderedDict{String, Any}()
    d["typename"]     = string(typeof(o))
    d["constructor"]  = "correlation_holder"
    d["alias"]        = serialise(o.alias)
    d["correlations"] = serialise(o.correlations)
    d["sep"]          = serialise(o.sep)
    return d
end
