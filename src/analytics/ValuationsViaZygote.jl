
"""
    model_price_and_deltas_zygote(
        payoffs::AbstractVector,
        path_obj::Path,
        pay_time::Union{ModelTime, Nothing} = nothing,
        discount_curve_key::Union{String,Nothing} = nothing
        )

Calculate model price and curve sensitivities.

Here, payoffs is a vector of `Payoff` objects and `path_obj` is a simulated `Path`.

`pay_time` and `discount_curve_key` control payoff discounting via
numeraire calculation.
"""
function model_price_and_deltas_zygote(
    payoffs::AbstractVector,
    path_obj::Path,
    pay_time::Union{ModelTime, Nothing} = nothing,
    discount_curve_key::Union{String,Nothing} = nothing,
    )
    if has_amc_payoff(payoffs)
        @warn "Zygote cannot properly handle AMC payoffs."
    end
    #
    pay_time = _effective_pay_time(payoffs, pay_time, discount_curve_key)
    #
    obj_function(ts_dict) = begin
        path_ = path(path_obj.sim, ts_dict, path_obj.context, path_obj.interpolation)
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
    # res = obj_function(path_obj.ts_dict)
    (v, g) = _function_value_and_gradient(obj_function, path_obj.ts_dict, Zygote)
    return (v, g)
end


"""
    model_price_and_vegas_zygote(
        payoffs::AbstractVector,
        model::CompositeModel,
        simulation::Function,
        ts_list::AbstractVector,
        context::Context,
        pay_time::Union{ModelTime, Nothing} = nothing,
        discount_curve_key::Union{String,Nothing} = nothing
        )

Calculate model price and model sensitivities.

Here, `payoffs` is a vector of `Payoff` objects, `model` is a full hybrid model.

`simulation` is a short cut for a `Simulation` constructor with the
signature `simulation(model::Model, ch::CorrelationHolder)`.

`ts_list` is a list of `TermStructure` objects for pricing and `context` is a
`Context` for valuation.

`pay_time` and `discount_curve_key` control payoff discounting via
numeraire calculation.
"""
function model_price_and_vegas_zygote(
    payoffs::AbstractVector,
    model::CompositeModel,
    simulation::Function,
    ts_list::AbstractVector,
    context::Context,
    pay_time::Union{ModelTime, Nothing} = nothing,
    discount_curve_key::Union{String,Nothing} = nothing
    )
    if has_amc_payoff(payoffs)
        @warn "Zygote cannot properly handle AMC payoffs."
    end
    #
    pay_time = _effective_pay_time(payoffs, pay_time, discount_curve_key)
    #
    param_dict = model_parameters(model)
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
    obj_function(param_dict) = begin
        mdl = build_model(alias(model), param_dict, model_dict)
        if !isnothing(ch_alias)
            ch = param_dict[ch_alias]
        else
            ch = correlation_holder("One")  # fall-back
        end
        sim = simulation(mdl, ch)
        path_ = path(sim, ts_list, context, LinearPathInterpolation)
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
    # res = obj_function(param_dict)
    (v, g) = _function_value_and_gradient(obj_function, param_dict, Zygote)
    return (v, g)
end
