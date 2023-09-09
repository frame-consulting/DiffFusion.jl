
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

Serialise PiecewiseFlatParameter.
"""
serialise(o::CorrelationHolder) = serialise_struct(o)
