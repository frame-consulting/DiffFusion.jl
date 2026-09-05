
"""
    abstract type QuasiGaussianShortRateModelFunction end

An abstract type for functors which implement a scalar volatility
function for the QuasiGaussianShortRateModel.

The functor implements broadcasting across paths.
"""
abstract type QuasiGaussianShortRateModelFunction end


"""
    struct GaussianShortRateModelFunction <: QuasiGaussianShortRateModelFunction end

A concrete type for a Gaussian short rate model function.
"""
struct GaussianShortRateModelFunction <: QuasiGaussianShortRateModelFunction end

(m::GaussianShortRateModelFunction)(s, t, x) = ones(size(x))


"""
    struct CirShortRateModelFunction{
        YieldTermstructureType<:YieldTermstructure
        } <: QuasiGaussianShortRateModelFunction
        ts::YieldTermstructureType
        min_value::Float64
    end

A concrete type for a CIR short rate model function.
"""
struct CirShortRateModelFunction{
    YieldTermstructureType<:YieldTermstructure
    } <: QuasiGaussianShortRateModelFunction
    ts::YieldTermstructureType
    min_value::Float64
end

(m::CirShortRateModelFunction)(s, t, x) = begin
    short_rate = zero_rate(m.ts, s, t)
    sqrt.(max.(m.min_value, short_rate .+ x))
end


"""
    struct QuasiGaussianShortRateModel{
            ModelType<:GaussianHjmModel,
            VolatilityFunctionType<:QuasiGaussianShortRateModelFunction,
        } <: QuasiGaussianModel
        #
        gaussian_model::ModelType
        state_alias::Vector{String}
        factor_alias::Vector{String}
        volatility_function::VolatilityFunctionType
    end

A one-factor quasi-Gaussian model with general local volatility function.

We specialise to a one-factor model and diagonal Gaussian model volatility scaling.

Model is intended specify volatility functions depending on the modelled short rate
which is derived from a state variable.

QuasiGaussianShortRateModelFunction is a functor which implements a scalar function
y = f(x) where x is the state variable of the model.

Typical instance for volatility function is f(x)=√r(x), where r(x) is the short rate.
Such a specification leads to CIR-like model.
"""
struct QuasiGaussianShortRateModel{
        ModelType<:GaussianHjmModel,
        VolatilityFunctionType<:QuasiGaussianShortRateModelFunction,
    } <: QuasiGaussianModel
    #
    gaussian_model::ModelType
    state_alias::Vector{String}
    factor_alias::Vector{String}
    volatility_function::VolatilityFunctionType
end


"""
    quasi_gaussian_short_rate_model(
    gaussian_model::GaussianHjmModel,
    volatility_function::QuasiGaussianShortRateModelFunction,
    )

Create a one-factor quasi-Gaussian short rate model with general local volatility
function from a Gaussian HJM model.
"""
function quasi_gaussian_short_rate_model(
    gaussian_model::GaussianHjmModel,
    volatility_function::QuasiGaussianShortRateModelFunction,
    )
    #
    d = length(gaussian_model.delta())
    @assert d == 1
    @assert gaussian_model.scaling_type == DiagonalScaling
    #
    alias_ = alias(gaussian_model)
    state_alias_x_z = state_alias(gaussian_model)
    state_alias_y = [ alias_ * "_y_1_1" ]  # relies on d=1
    state_alias_x_z_y = vcat(state_alias_x_z, state_alias_y)
    @assert length(state_alias_x_z_y) == 3
    #
    factor_alias_x = factor_alias(gaussian_model)
    #
    return QuasiGaussianShortRateModel(
        gaussian_model,
        state_alias_x_z_y,
        factor_alias_x,
        volatility_function,
    )
end


"""
    quasi_gaussian_short_rate_model(
    alias::String,
    chi::ParameterTermstructure,
    sigma_f::BackwardFlatVolatility,
    quanto_model::Union{AssetModel, Nothing},
    volatility_function::QuasiGaussianShortRateModelFunction,
    )

Create a one-factor quasi-Gaussian short rate model with general local volatility
function from model parameters.
"""
function quasi_gaussian_short_rate_model(
    alias::String,
    chi::ParameterTermstructure,
    sigma_f::BackwardFlatVolatility,
    quanto_model::Union{AssetModel, Nothing},
    volatility_function::QuasiGaussianShortRateModelFunction,
    )
    #
    @assert length(chi()) == 1
    @assert length(sigma_f(0.0)) == 1
    delta = flat_parameter(0.0)
    correlation_holder = nothing
    scaling_type = DiagonalScaling
    gaussian_model = gaussian_hjm_model(
        alias,
        delta,
        chi,
        sigma_f,
        correlation_holder,
        quanto_model,
        scaling_type,
    )
    return quasi_gaussian_short_rate_model(
        gaussian_model,
        volatility_function,
    )
end


"""
    func_sigma_f(
        m::QuasiGaussianShortRateModel,
        s::ModelTime,
        t::ModelTime,
        X::ModelState,
        )

Calculate the benchmark-rate local/stochastic volatility for the interval
(s, t).

This method assumes that local volatility is constant on the interval (s, t).
"""
function func_sigma_f(
    m::QuasiGaussianShortRateModel,
    s::ModelTime,
    t::ModelTime,
    X::ModelState,
    )
    #
    @assert is_constant(m.gaussian_model.sigma_T.sigma_f, s, t)
    u = 0.5 * (s + t)  # mid-point rule
    sigma_0 = m.gaussian_model.sigma_T.sigma_f(u)  # (d,) vector, where d = 1
    #
    X_ = state_variable(m, X)  # (d, p) matrix, where d = 1
    f = m.volatility_function(s, t, X_)
    #
    return sigma_0 .* f  # (d, p) matrix, where d = 1
end
