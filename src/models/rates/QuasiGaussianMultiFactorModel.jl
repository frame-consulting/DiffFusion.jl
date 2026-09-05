
"""
    struct QuasiGaussianMultiFactorModel <: QuasiGaussianModel
        gaussian_model::GaussianHjmModel
        slope_d::BackwardFlatParameter
        slope_u::BackwardFlatParameter
        sigma_min::ModelValue
        sigma_max::ModelValue
        state_alias::AbstractVector
        factor_alias::AbstractVector
        volatility_model::Union{ComponentModel, Nothing}
        volatility_function::Union{Function, Nothing}
    end

A quasi-Gaussian model with piece-wise constant local volatility slope
parameters and (optional) stochastic volatility model.

QuasiGaussianMultiFactorModel model generalises GaussianHjmModel.
"""
struct QuasiGaussianMultiFactorModel{
        ModelType<:GaussianHjmModel,
        SkewType<:ModelValue,
        VolModelType<:Union{ComponentModel, Nothing},
    } <: QuasiGaussianModel
    #
    gaussian_model::ModelType
    slope_d::BackwardFlatParameter{SkewType}
    slope_u::BackwardFlatParameter{SkewType}
    sigma_min::Float64
    sigma_max::Float64
    state_alias::Vector{String}
    factor_alias::Vector{String}
    volatility_model::VolModelType
    volatility_function::Union{Function, Nothing}
end


"""
    quasi_gaussian_multi_factor_model(
        gaussian_model::GaussianHjmModel,
        slope_d::BackwardFlatParameter,
        slope_u::BackwardFlatParameter,
        sigma_min::ModelValue,
        sigma_max::ModelValue,
        volatility_model::Union{ComponentModel, Nothing} = nothing,
        volatility_function::Union{Function, Nothing} = nothing,
        )

Create a quasi-Gaussian model based on a GaussianHjmModel.
"""
function quasi_gaussian_multi_factor_model(
    gaussian_model::GaussianHjmModel,
    slope_d::BackwardFlatParameter,
    slope_u::BackwardFlatParameter,
    sigma_min::ModelValue,
    sigma_max::ModelValue,
    volatility_model::Union{ComponentModel, Nothing} = nothing,
    volatility_function::Union{Function, Nothing} = nothing,
    )
    #
    d = length(gaussian_model.delta())
    n_time_grid = length(gaussian_model.sigma_T.sigma_f.times)
    @assert length(slope_d(0.0)) == d
    @assert length(slope_u(0.0)) == d
    @assert length(slope_d.times) == n_time_grid
    @assert length(slope_u.times) == n_time_grid
    @assert sigma_min > 0.0
    @assert sigma_max ≥ sigma_min
    @assert !isnothing(volatility_model) || isnothing(volatility_function)
    @assert !isnothing(volatility_function) || isnothing(volatility_model)
    #
    alias_ = alias(gaussian_model)
    state_alias_x_z = state_alias(gaussian_model)
    state_alias_y = vec([
        alias_ * "_y_" * string(k) * "_" * string(l)
        for k in 1:d, l in 1:d
    ])
    state_alias_x_z_y = vcat(state_alias_x_z, state_alias_y)
    @assert length(state_alias_x_z_y) == d + 1 + d*d
    #
    factor_alias_x = factor_alias(gaussian_model)
    #
    return QuasiGaussianMultiFactorModel(
        gaussian_model,
        slope_d,
        slope_u,
        sigma_min,
        sigma_max,
        state_alias_x_z_y,
        factor_alias_x,
        volatility_model,
        volatility_function,
    )
end


"""
    quasi_gaussian_multi_factor_model(
        alias::String,
        delta::ParameterTermstructure,
        chi::ParameterTermstructure,
        sigma_f::BackwardFlatVolatility,
        slope_d::BackwardFlatParameter,
        slope_u::BackwardFlatParameter,
        sigma_min::ModelValue,
        sigma_max::ModelValue,
        correlation_holder::Union{CorrelationHolder, Nothing},
        quanto_model::Union{AssetModel, Nothing},
        scaling_type::BenchmarkTimesScaling = _default_benchmark_time_scaling,
        volatility_model::Union{ComponentModel, Nothing} = nothing,
        volatility_function::Union{Function, Nothing} = nothing,
        )

Create a quasi-Gaussian model from direct inputs.
"""
function quasi_gaussian_multi_factor_model(
    alias::String,
    delta::ParameterTermstructure,
    chi::ParameterTermstructure,
    sigma_f::BackwardFlatVolatility,
    slope_d::BackwardFlatParameter,
    slope_u::BackwardFlatParameter,
    sigma_min::ModelValue,
    sigma_max::ModelValue,
    correlation_holder::Union{CorrelationHolder, Nothing},
    quanto_model::Union{AssetModel, Nothing},
    scaling_type::BenchmarkTimesScaling = _default_benchmark_time_scaling,
    volatility_model::Union{ComponentModel, Nothing} = nothing,
    volatility_function::Union{Function, Nothing} = nothing,
    )
    #
    gaussian_model = gaussian_hjm_model(
        alias,
        delta,
        chi,
        sigma_f,
        correlation_holder,
        quanto_model,
        scaling_type,
    )
    #
    return quasi_gaussian_multi_factor_model(
        gaussian_model,
        slope_d,
        slope_u,
        sigma_min,
        sigma_max,
        volatility_model,
        volatility_function,
    )
end

# Volatility specification

"""
    stochastic_volatility(
        volatility_model::ComponentModel,
        volatility_function::Function,
        X::ModelState,
        )

Calculate stochastic volatility.
"""
function stochastic_volatility(
    volatility_model::ComponentModel,
    volatility_function::Function,
    X::ModelState,
    )
    #
    idx = X.idx[state_alias(volatility_model)[begin]]  # maybe better use a model function as indirection
    nu = @view(X.X[idx:idx, :])
    gamma = volatility_function.(nu)
    return gamma  # as (1, p) matrix
end


"""
    stochastic_volatility(
        volatility_model::Nothing,
        volatility_function::Nothing,
        X::ModelState,
        )

Dispatch stochastic volatility calculation model/function is nothing.
"""
function stochastic_volatility(
    volatility_model::Nothing,
    volatility_function::Nothing,
    X::ModelState,
    )
    #
    return 1.0
end


"""
    func_sigma_f(
        m::QuasiGaussianMultiFactorModel,
        s::ModelTime,
        t::ModelTime,
        X::ModelState,
        )

Calculate the benchmark-rate local/stochastic volatility for the interval
(s, t).

This method assumes that local volatility is constant on the interval (s, t).
"""
function func_sigma_f(
    m::QuasiGaussianMultiFactorModel,
    s::ModelTime,
    t::ModelTime,
    X::ModelState,
    )
    #
    @assert is_constant(m.gaussian_model.sigma_T.sigma_f, s, t)
    u = 0.5 * (s + t)  # mid-point rule
    sigma_0 = m.gaussian_model.sigma_T.sigma_f(u)
    slope_d = m.slope_d(u)
    slope_u = m.slope_u(u)
    #
    X_ = state_variable(m, X)
    X_d = max.(-1.0 .* X_, 0.0)
    X_u = max.(        X_, 0.0)
    #
    gamma = stochastic_volatility(m.volatility_model, m.volatility_function, X)
    # as (d, p) matrix
    return min.(max.(gamma .* (sigma_0 .+ slope_d .* X_d .+ slope_u .* X_u), m.sigma_min), m.sigma_max)
end
