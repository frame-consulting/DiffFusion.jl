
"""
    serialise(o::Context)

Serialise model Context.
"""
serialise(o::Context) = serialise_struct(o)


"""
    serialise(o::BenchmarkTimesScaling)

Serialise a BenchmarkTimesScaling enumeration object.
"""
function serialise(o::BenchmarkTimesScaling)
    d = OrderedDict{String, Any}()
    d["typename"]    = string(typeof(o))
    d["constructor"] = "BenchmarkTimesScaling"
    d["enumeration"] = Integer(o)
    return d
end


"""
    serialise(o::GaussianHjmModel)

Serialise GaussianHjmModel.
"""
function serialise(o::GaussianHjmModel)
    d = OrderedDict{String, Any}()
    d["typename"]    = string(typeof(o))
    d["constructor"] = "gaussian_hjm_model"
    d["alias"]       = serialise(o.alias)
    d["delta"]       = serialise(o.delta)
    d["chi"]         = serialise(o.chi)
    d["sigma_f"]     = serialise(o.sigma_T.sigma_f)
    if isnothing(o.correlation_holder)
        d["correlation_holder"]  = serialise(o.correlation_holder)
    else
        d["correlation_holder"]  = serialise_key(o.correlation_holder.alias)
    end
    if isnothing(o.quanto_model)
        d["quanto_model"] = serialise(o.quanto_model)
    else
        d["quanto_model"] = serialise_key(o.quanto_model.alias)
    end
    if o.scaling_type != _default_benchmark_time_scaling
        d["scaling_type"] = serialise(o.scaling_type)
    end
    return d
end


"""
    serialise(o::QuasiGaussianModel)

Serialise QuasiGaussianModel.
"""
function serialise(o::QuasiGaussianModel)
    g = o.gaussian_model
    d = OrderedDict{String, Any}()
    d["typename"]    = string(typeof(o))
    d["constructor"] = "quasi_gaussian_model"
    d["alias"]       = serialise(g.alias)
    d["delta"]       = serialise(g.delta)
    d["chi"]         = serialise(g.chi)
    d["sigma_f"]     = serialise(g.sigma_T.sigma_f)
    d["slope_d"]     = serialise(o.slope_d)
    d["slope_u"]     = serialise(o.slope_u)
    d["sigma_min"]   = serialise(o.sigma_min)
    d["sigma_max"]   = serialise(o.sigma_max)
    if isnothing(g.correlation_holder)
        d["correlation_holder"]  = serialise(g.correlation_holder)
    else
        d["correlation_holder"]  = serialise_key(g.correlation_holder.alias)
    end
    if isnothing(g.quanto_model)
        d["quanto_model"] = serialise(g.quanto_model)
    else
        d["quanto_model"] = serialise_key(g.quanto_model.alias)
    end
    d["scaling_type"] = serialise(g.scaling_type)
    if isnothing(o.volatility_model)
        d["volatility_model"] = serialise(o.volatility_model)
    else
        d["volatility_model"] = serialise_key(o.volatility_model.alias)
    end
    if isnothing(o.volatility_function)
        d["volatility_function"] = serialise(o.volatility_function)
    else
        d["volatility_function"] = serialise(o.volatility_function)
    end
    #
    return d
end


"""
    serialise(o::LognormalAssetModel)

Serialise LognormalAssetModel.
"""
function serialise(o::LognormalAssetModel)
    d = OrderedDict{String, Any}()
    d["typename"]    = string(typeof(o))
    d["constructor"] = "lognormal_asset_model"
    d["alias"]       = serialise(o.alias)
    d["sigma_x"]     = serialise(o.sigma_x)
    d["correlation_holder"] = serialise_key(o.correlation_holder.alias)
    if isnothing(o.quanto_model)
        d["quanto_model"] = serialise(o.quanto_model)
    else
        d["quanto_model"] = serialise_key(o.quanto_model.alias)
    end
    return d
end


"""
    serialise(o::CevAssetModel)

Serialise CevAssetModel.
"""
function serialise(o::CevAssetModel)
    d = OrderedDict{String, Any}()
    d["typename"]    = string(typeof(o))
    d["constructor"] = "cev_asset_model"
    d["alias"]       = serialise(o.alias)
    d["sigma_x"]     = serialise(o.sigma_x)
    d["skew_x"]      = serialise(o.skew_x)
    d["correlation_holder"] = serialise_key(o.correlation_holder.alias)
    if isnothing(o.quanto_model)
        d["quanto_model"] = serialise(o.quanto_model)
    else
        d["quanto_model"] = serialise_key(o.quanto_model.alias)
    end
    return d
end


"""
    serialise(o::OrnsteinUhlenbeckModel)

Serialise OrnsteinUhlenbeckModel.
"""
function serialise(o::OrnsteinUhlenbeckModel)
    d = OrderedDict{String, Any}()
    d["typename"]    = string(typeof(o))
    d["constructor"] = "ornstein_uhlenbeck_model"
    d["alias"]       = serialise(o.alias)
    d["chi"]         = serialise(o.chi)
    d["sigma_x"]     = serialise(o.sigma_x)
    return d
end


"""
    serialise(o::SimpleModel)

Serialise SimpleModel.
"""
function serialise(o::SimpleModel)
    d = OrderedDict{String, Any}()
    d["typename"]    = string(typeof(o))
    d["constructor"] = "simple_model"
    d["alias"]       = serialise(o.alias)
    d["models"]      = serialise([ m for m in o.models ])
    return d
end


"""
    serialise_as_list(o::SimpleModel)

Serialise SimpleModel as a list and capture references.
"""
function serialise_as_list(o::SimpleModel)
    obj_dict = OrderedDict{String, Any}()
    function get_obj!(property_name)
        for model in o.models
            if hasproperty(model, property_name)
                obj = getproperty(model, property_name)
                if !isnothing(obj)
                    @assert hasproperty(obj, :alias)
                    obj_dict[obj.alias] = obj
                end
            end
        end
    end
    #
    get_obj!(:correlation_holder)
    get_obj!(:quanto_model)
    for model in o.models
        obj_dict[model.alias] = model
    end
    dict_list = [ serialise(obj_dict[key]) for key in keys(obj_dict) ]
    #
    d = OrderedDict{String, Any}()
    d["typename"]    = string(typeof(o))
    d["constructor"] = "simple_model"
    d["alias"]       = serialise(o.alias)
    d["models"]      = [ serialise_key(m.alias) for m in o.models ]
    push!(dict_list, d)
    return dict_list
end
