
"""
    _effective_pay_time(
        payoffs::AbstractVector,
        pay_time::Union{ModelTime, Nothing} = nothing,
        discount_curve_key::Union{String,Nothing} = nothing
        )

Determine pay time from payoff or input.
"""
function _effective_pay_time(
    payoffs::AbstractVector,
    pay_time::Union{ModelTime, Nothing} = nothing,
    discount_curve_key::Union{String,Nothing} = nothing
    )
    #
    if !isnothing(discount_curve_key) # pay time is only relevant if discounting
        if length(payoffs) > 0
            max_time = maximum(obs_time, payoffs)
        else
            max_time = 0.0
        end
        if isnothing(pay_time)
            pay_time = max_time
        end
        @assert pay_time >= max_time    
    end
    return pay_time
end


"""
    model_price(
        payoffs::AbstractVector,
        path_obj::Path,
        pay_time::Union{ModelTime, Nothing} = nothing,
        discount_curve_key::Union{String,Nothing} = nothing
        )

Calculate model price for a vector of `Payoff` objects.
"""
function model_price(
    payoffs::AbstractVector,
    path_obj::Path,
    pay_time::Union{ModelTime, Nothing} = nothing,
    discount_curve_key::Union{String,Nothing} = nothing
    )
    #
    pay_time = _effective_pay_time(payoffs, pay_time, discount_curve_key)
    #
    X = zeros(length(path_obj))
    if length(payoffs) > 0
        X += sum(( p(path_obj) for p in payoffs ))
    end
    if !isnothing(discount_curve_key)
        num = numeraire(path_obj, pay_time, discount_curve_key)
        X = X ./ num
    end
    return mean( X )
end


"""
    model_price_and_deltas(
        payoffs::AbstractVector,
        path_obj::Path,
        pay_time::Union{ModelTime, Nothing} = nothing,
        discount_curve_key::Union{String,Nothing} = nothing,
        ad_module::Module = ForwardDiff,
        )

Calculate model price and curve sensitivities. Sensitivities are
calculated as vector together with a vector of labels.

Here, payoffs is a vector of `Payoff` objects and `path_obj` is a simulated `Path`.

`pay_time` and `discount_curve_key` control payoff discounting via
numeraire calculation.

`ad_module` can be `Zygote` or `ForwardDiff`.

For AMC payoffs we need to update the regression path and trigger a
recalibration. For sensitivity calculation, we impose the constraint that
regression calibration uses the same paths as valuation.
"""
function model_price_and_deltas(
    payoffs::AbstractVector,
    path_obj::Path,
    pay_time::Union{ModelTime, Nothing} = nothing,
    discount_curve_key::Union{String,Nothing} = nothing,
    ad_module::Module = ForwardDiff,
    )
    #
    if has_amc_payoff(payoffs) && (ad_module == Zygote)
        @warn "Zygote cannot properly handle AMC payoffs."
    end
    #
    pay_time = _effective_pay_time(payoffs, pay_time, discount_curve_key)
    ts_dict = deepcopy(path_obj.ts_dict)  # maybe we don't want (or need) this
    (ts_labels, ts_values) = termstructure_values(ts_dict)
    #
    obj_function(ts_values_) = begin
        termstructure_dictionary!(ts_dict, ts_labels, ts_values_)
        path_ = path(path_obj.sim, ts_dict, path_obj.context, path_obj.interpolation)
        # we need to update regression paths for AMC payoffs
        for p in payoffs
            reset_regression!(p, path_)
        end
        #
        X = zeros(length(path_))
        if length(payoffs) > 0
            X += sum(( p(path_) for p in payoffs ))
        end
        if !isnothing(discount_curve_key)
            num = numeraire(path_, pay_time, discount_curve_key)
            X = X ./ num
        end
        return mean( X )
    end
    (v, g) = _function_value_and_gradient(obj_function, ts_values, ad_module)
    return (v, g, ts_labels)
end


"""
    model_price_and_vegas(
        payoffs::AbstractVector,
        model::CompositeModel,
        simulation::Function,
        ts_list::AbstractVector,
        context::Context,
        pay_time::Union{ModelTime, Nothing} = nothing,
        discount_curve_key::Union{String,Nothing} = nothing,
        ad_module::Module = ForwardDiff,
        )

Calculate model price and model sensitivities. Sensitivities are
calculated as vector together with a vector of labels.

Here, `payoffs` is a vector of `Payoff` objects, `model` is a full hybrid model.

`simulation` is a short cut for a `Simulation` constructor with the
signature `simulation(model::Model, ch::CorrelationHolder)`.

`ts_list` is a list of `TermStructure` objects for pricing and `context` is a
`Context` for valuation.

`pay_time` and `discount_curve_key` control payoff discounting via
numeraire calculation.

`ad_module` can be `Zygote` or `ForwardDiff`.

For AMC payoffs we need to update the regression path and trigger a
recalibration. For sensitivity calculation, we impose the constraint that
regression calibration uses the same paths as valuation.
"""
function model_price_and_vegas(
    payoffs::AbstractVector,
    model::CompositeModel,
    simulation::Function,
    ts_list::AbstractVector,
    context::Context,
    pay_time::Union{ModelTime, Nothing} = nothing,
    discount_curve_key::Union{String,Nothing} = nothing,
    ad_module::Module = ForwardDiff,
    )
    #
    if has_amc_payoff(payoffs) && (ad_module == Zygote)
        @warn "Zygote cannot properly handle AMC payoffs."
    end
    #
    pay_time = _effective_pay_time(payoffs, pay_time, discount_curve_key)
    #
    param_dict = model_parameters(model)
    (vol_labels, vol_values) = model_volatility_values(model.alias, param_dict)
    model_dict = Dict{String, Any}()
    # We need a correlation holder... for simplicity, we assume this is unique in the model
    ch_alias = nothing
    for m in model.models
        if hasproperty(m, :correlation_holder) &&
            !isnothing(m.correlation_holder) &&
            length(m.correlation_holder.correlations) > 0  # avoid Zygote error by differentiating empty dict
            #
            ch_alias = m.correlation_holder.alias
            break
        end
    end
    obj_function(vol_values) = begin
        model_parameters!(param_dict, vol_labels, vol_values)
        mdl = build_model(alias(model), param_dict, model_dict)
        if !isnothing(ch_alias)
            ch = param_dict[ch_alias]
        else
            ch = correlation_holder("One")  # fall-back
        end
        sim = simulation(mdl, ch)
        path_ = path(sim, ts_list, context, LinearPathInterpolation)
        # we need to update regression paths for AMC payoffs
        for p in payoffs
            reset_regression!(p, path_)
        end
        #
        X = zeros(length(path_))
        if length(payoffs) > 0
            X += sum(( p(path_) for p in payoffs ))
        end
        if !isnothing(discount_curve_key)
            num = numeraire(path_, pay_time, discount_curve_key)
            X = X ./ num
        end
        price = mean( X )
        return price
    end
    # res = obj_function(vol_values)
    (v, g) = _function_value_and_gradient(obj_function, vol_values, ad_module)
    return (v, g, vol_labels)
end
