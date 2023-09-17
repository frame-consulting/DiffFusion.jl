
"""
This file contains methods to extract term structures and re-build models.

Methods are intended to be used for sensitivity calculations. For that
purpose we need to identify model parameters as inputs to the valuation
function.
"""

"""
    model_parameters(m::GaussianHjmModel)

Extract model parameters from GaussianHjmModel.
"""
function model_parameters(m::GaussianHjmModel)
    d = Dict{String, Any}()
    d["type"]    = typeof(m)
    d["alias"]   = m.alias
    d["delta"]   = m.delta
    d["chi"]     = m.chi
    d["sigma_f"] = m.sigma_T.sigma_f
    if isnothing(m.correlation_holder)
        d["correlation_holder"]  = nothing
    else
        d["correlation_holder"]  = m.correlation_holder.alias
    end
    if isnothing(m.quanto_model)
        d["quanto_model"] = nothing
    else
        d["quanto_model"] = m.quanto_model.alias
    end
    # we add another dict layer to allow combining models and ts.
    return Dict(m.alias => d)
end


"""
    model_parameters(m::LognormalAssetModel)

Extract model parameters from LognormalAssetModel.
"""
function model_parameters(m::LognormalAssetModel)
    d = Dict{String, Any}()
    d["type"]    = typeof(m)
    d["alias"]   = m.alias
    d["sigma_x"] = m.sigma_x
    d["correlation_holder"]  = m.correlation_holder.alias  # LognormalAssetModel must have correlation_holder
    if isnothing(m.quanto_model) # quanto model is optional
        d["quanto_model"] = nothing
    else
        d["quanto_model"] = m.quanto_model.alias
    end
    # we add another dict layer to allow combining models and ts.
    return Dict(m.alias => d)
end


"""
    model_parameters(m::SimpleModel)

Extract model parameters from SimpleModel.
"""
function model_parameters(m::SimpleModel)
    d = Dict{String, Any}()
    # meta date
    d[m.alias] = Dict(
        "type" => typeof(m),
        "alias" => m.alias,
        "models" => [ m.alias for m in m.models ],   
    )
    # model data
    for model in m.models
        if hasproperty(model, :correlation_holder) && !isnothing(model.correlation_holder)
            d[model.correlation_holder.alias] = model.correlation_holder
        end
    end
    for model in m.models
        d[model.alias] = model_parameters(model)[model.alias]
    end
    return d
end



"""
    build_model(
         alias::String,
         param_dict::Dict,
         model_dict::Dict,
         )

Re-build a model from model parameters dictionary.

Alias identifies the model which is to be build. Input parameter
term structures are stored in param_dict. The model_dict is used
to reference quanto models.
"""
function build_model(
    alias::String,
    param_dict::Dict,
    model_dict::Dict,
    )
    @assert(haskey(param_dict, alias))
    m_dict = param_dict[alias]
    @assert(haskey(m_dict, "type"))
    if m_dict["type"] == GaussianHjmModel
        if isnothing(m_dict["correlation_holder"])
            ch = nothing
        else
            ch = param_dict[m_dict["correlation_holder"]]
        end
        if isnothing(m_dict["quanto_model"])
            quanto_model = nothing
        else
            quanto_model = model_dict[m_dict["quanto_model"]]
        end
        return gaussian_hjm_model(
            m_dict["alias"],
            m_dict["delta"],
            m_dict["chi"],
            m_dict["sigma_f"],
            ch,
            quanto_model,
        )
    end
    if m_dict["type"] == LognormalAssetModel
        ch = param_dict[m_dict["correlation_holder"]]  # LognormalAssetModel requires correlation_holder
        if isnothing(m_dict["quanto_model"])
            quanto_model = nothing
        else
            quanto_model = model_dict[m_dict["quanto_model"]]
        end
        return lognormal_asset_model(
            m_dict["alias"],
            m_dict["sigma_x"],
            ch,
            quanto_model,
        )
    end
    if m_dict["type"] == SimpleModel
        simple_model_dict = Dict{String, Any}()
        for a in m_dict["models"]
            # here the order of models is relevant
            simple_model_dict[a] = build_model(a, param_dict, simple_model_dict)
        end
        models = [ simple_model_dict[a] for a in m_dict["models"] ]
        return simple_model(
            m_dict["alias"],
            models
        )
    end
end


"We specify how to split aliases from volatilities."
const _split_alias_identifyer = " "

"""
    _get_labels_and_values(
        alias::AbstractString,
        param_key::AbstractString,
        m_dict::Dict,
        )

Extract labels and values from model dictionary.
"""
function _get_labels_and_values(
    alias::AbstractString,
    param_key::AbstractString,
    m_dict::Dict,
    )
    #
    param_times = m_dict[param_key].times
    param_values = m_dict[param_key].values
    param_labels = [
        alias     * _split_alias_identifyer *
        param_key   * _split_alias_identifyer *
        string(i) * _split_alias_identifyer *
        (@sprintf("%.2f", param_times[j]))
        for i in 1:size(param_values)[1], j in 1:size(param_values)[2]
    ]
    return (vec(permutedims(param_labels)), vec(permutedims(param_values)))
end

"""
    _unique_strings(s::AbstractVector)

Remove duplicates.

We use a dedicated function to flag it as non-differentiable
and avoid errors from unique(.) function.
"""
_unique_strings(s::AbstractVector) = unique(s)

"""
    _restructure_parameters(
        param_labels::AbstractVector,
        param_values::AbstractVector,
        )

Split and re-structure parameters from vector.
"""
function _restructure_parameters(
    param_labels::AbstractVector,
    param_values::AbstractVector,
    )
    #
    alias_vec = [
        split(s, _split_alias_identifyer)[1]
        for s in param_labels
    ]
    param_key_vec = [
        split(s, _split_alias_identifyer)[2]
        for s in param_labels
    ]
    alias_dict = Dict{AbstractString, Any}()
    alias_vec_unique = _unique_strings(alias_vec)
    for alias in alias_vec_unique
        param_keys = param_key_vec[ alias_vec .== alias ]
        param_dict = Dict{AbstractString, Any}()
        param_keys_unique = _unique_strings(param_keys)
        for param_key in param_keys_unique
            values = param_values[(alias_vec.==alias) .& (param_key_vec.==param_key)]
            param_dict[param_key] = values
        end
        alias_dict[alias] = param_dict
    end
    return alias_dict
end


"""
    model_volatility_values(
        alias::String,
        param_dict::Dict,
        )

Extract volatility labels and values from model parameters.
"""
function model_volatility_values(
    alias::String,
    param_dict::Dict,
    )
    #
    @assert(haskey(param_dict, alias))
    m_dict = param_dict[alias]
    #
    @assert(haskey(m_dict, "type"))
    if m_dict["type"] == GaussianHjmModel
        return _get_labels_and_values(alias, "sigma_f", m_dict)
    end
    if m_dict["type"] == LognormalAssetModel
        return _get_labels_and_values(alias, "sigma_x", m_dict)
    end
    if m_dict["type"] == SimpleModel
        vol_labels_values = [
            model_volatility_values(a, param_dict)
            for a in m_dict["models"]
        ]
        vol_labels = vcat([lv[1] for lv in vol_labels_values]...)
        vol_values = vcat([lv[2] for lv in vol_labels_values]...)
        return (vol_labels, vol_values)
    end
    error("Unknown model type in m_dict.")
end


"""
    model_parameters!(
        param_dict::Dict,
        param_labels::AbstractVector,
        param_values::AbstractVector,
        )

Re-build model parameter dictionary from volatility labels and values.
"""
function model_parameters!(
    param_dict::Dict,
    param_labels::AbstractVector,
    param_values::AbstractVector,
    )
    #
    param_value_dict = _restructure_parameters(param_labels, param_values)
    for (m_alias, p_dict) in param_value_dict
        @assert m_alias in keys(param_dict)
        for (param_key, value_vector) in p_dict
            @assert param_key in keys(param_dict[m_alias])
            ts = param_dict[m_alias][param_key]
            # the following methodology must revert _get_labels_and_values(...)
            ts_size = size(ts.values)
            value_matrix = reshape(param_value_dict[m_alias][param_key], (ts_size[2],ts_size[1]))
            value_matrix = permutedims(value_matrix)
            #
            @assert isa(ts, BackwardFlatVolatility)  # deal with other cases later...
            ts_new = backward_flat_volatility(ts.alias, ts.times, value_matrix)
            param_dict[m_alias][param_key] = ts_new  # re-set (and activate) term structure
        end
    end
    return param_dict
end
