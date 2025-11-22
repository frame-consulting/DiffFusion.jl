"""
This file contains methods to extract term structure values and re-build
term structure dictionaries.

Methods are intended to be used for sensitivity calculations. For that
purpose we need to identify structure values as inputs to the valuation
function.
"""


"""
    _get_labels_and_values(ts::FlatForward)

Extract labels and values from FlatForward.
"""
function _get_labels_and_values(ts::FlatForward)
    param_labels = [
        alias(ts) * _split_alias_identifyer *
        string(typeof(ts)) * _split_alias_identifyer *
        "rate"
    ]
    param_values = [ ts.rate ]
    return ( param_labels, param_values )
end


"""
    _get_labels_and_values(ts::ZeroCurve)

Extract labels and values from ZeroCurve.
"""
function _get_labels_and_values(ts::ZeroCurve)
    param_labels = [
        alias(ts) * _split_alias_identifyer *
        string(typeof(ts)) * _split_alias_identifyer *
        (@sprintf("%.2f", t))
        for t in ts.times
    ]
    return ( param_labels, ts.values )
end


"""
    _get_labels_and_values(ts::LinearZeroCurve)

Extract labels and values from LinearZeroCurve.
"""
function _get_labels_and_values(ts::LinearZeroCurve)
    param_labels = [
        alias(ts) * _split_alias_identifyer *
        string(typeof(ts)) * _split_alias_identifyer *
        (@sprintf("%.2f", t))
        for t in ts.times
    ]
    return ( param_labels, ts.values )
end


"""
    _get_labels_and_values(ts::PiecewiseFlatParameter)

Extract labels and values from PiecewiseFlatParameter.
"""
function _get_labels_and_values(ts::PiecewiseFlatParameter)
    @assert(size(ts.values)[1] == 1)  # we need to deal with multi-factor parameters separately 
    param_labels = [
        alias(ts) * _split_alias_identifyer *
        string(typeof(ts)) * _split_alias_identifyer *
        (@sprintf("%.2f", t))
        for t in ts.times
    ]
    return ( param_labels, ts.values[1,:] )
end


"""
    termstructure_values(ts_dict::AbstractDict)

Extract term structure labels and values from term structure dictionary
"""
function termstructure_values(ts_dict::AbstractDict)
    ts_labels_values = [ _get_labels_and_values(ts) for ts in values(ts_dict) ]
    ts_labels = vcat([lv[1] for lv in ts_labels_values]...)
    ts_values = vcat([lv[2] for lv in ts_labels_values]...)
    return (ts_labels, ts_values)
end


"""
    termstructure_dictionary!(
        ts_dict::AbstractDict,
        ts_labels::AbstractVector,
        ts_values::AbstractVector,
        )

Re-build term structure dictionary from labels and values.
"""
function termstructure_dictionary!(
    ts_dict::AbstractDict,
    ts_labels::AbstractVector,
    ts_values::AbstractVector,
    )
    #
    ts_value_dict = _restructure_parameters(ts_labels, ts_values)
    for (ts_alias, ts_dict_) in ts_value_dict
        @assert ts_alias in keys(ts_dict)
        @assert length(keys(ts_dict_)) == 1
        ts_type_string = first(keys(ts_dict_))
        @assert string(typeof(ts_dict[ts_alias])) == ts_type_string
        #
        values = ts_dict_[ts_type_string]
        if isa(ts_dict[ts_alias], FlatForward)
            @assert size(values) == (1,)
            ts_dict[ts_alias] = flat_forward(ts_dict[ts_alias].alias, values[1])
            continue
        end
        if isa(ts_dict[ts_alias], ZeroCurve)
            non_differentiable_warn("ZeroCurve rebuild does not work with Zygote. Consider using LinearZeroCurve.")
            ts_dict[ts_alias] = zero_curve(ts_dict[ts_alias].alias, ts_dict[ts_alias].times, values)
            continue
        end
        if isa(ts_dict[ts_alias], LinearZeroCurve)
            ts_dict[ts_alias] = linear_zero_curve(ts_dict[ts_alias].alias, ts_dict[ts_alias].times, values)
            continue
        end
        if isa(ts_dict[ts_alias], BackwardFlatParameter)
            ts_dict[ts_alias] = backward_flat_parameter(ts_dict[ts_alias].alias, ts_dict[ts_alias].times, values)
            continue
        end
        if isa(ts_dict[ts_alias], ForwardFlatParameter)
            ts_dict[ts_alias] = forward_flat_parameter(ts_dict[ts_alias].alias, ts_dict[ts_alias].times, values)
            continue
        end
        #
        # Add further term structures here.
        #
        error("Termstructure type " * string(typeof(ts_dict[ts_alias])) * " not supported.")
    end
    return ts_dict
end
