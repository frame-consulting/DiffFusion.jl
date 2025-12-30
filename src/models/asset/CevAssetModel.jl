
"""
    struct CevAssetModel <: AssetModel
        alias::String
        sigma_x::BackwardFlatVolatility{ModelValue}
        skew_x::BackwardFlatParameter{ModelValue}
        state_alias::Vector{String}
        factor_alias::Vector{String}
        correlation_holder::CorrelationHolder{ModelValue}
        quanto_model::Union{AssetModel, Nothing}
    end

A `CevAssetModel` is a model for simulating an asset price in a
Constant Elasticity of Variance model.
"""
struct CevAssetModel{T1<:ModelValue, T2<:ModelValue, T3<:Union{AssetModel, Nothing}} <: AssetModel
    alias::String
    sigma_x::BackwardFlatVolatility{T1}
    skew_x::BackwardFlatParameter{T1}
    state_alias::Vector{String}
    factor_alias::Vector{String}
    correlation_holder::CorrelationHolder{T2}
    quanto_model::T3
end


"""
    cev_asset_model(
        alias::String,
        sigma_x::BackwardFlatVolatility,
        skew_x::BackwardFlatParameter,
        ch::CorrelationHolder,
        quanto_model::Union{AssetModel, Nothing}
        )

Create a CevAssetModel.
"""
function cev_asset_model(
    alias::String,
    sigma_x::BackwardFlatVolatility,
    skew_x::BackwardFlatParameter,
    ch::CorrelationHolder,
    quanto_model::Union{AssetModel, Nothing}
    )
    @assert size(sigma_x.values)[1] == 1
    @assert size(skew_x.values)[1] == 1
    state_alias = [ alias * "_x" ]
    factor_alias = [ alias * "_x" ]
    return CevAssetModel(alias, sigma_x, skew_x, state_alias, factor_alias, ch, quanto_model)
end


"""
    parameter_grid(m::CevAssetModel)

Return a list of times representing the (joint) grid points of piece-wise
constant model parameters.

This method is intended to be used in conjunction with time-integration
mehods that require smooth integrand functions.
"""
function parameter_grid(m::CevAssetModel)
    # better also add skew parameters here...
    return m.sigma_x.times
end

"""
    state_dependent_Theta(m::CevAssetModel)

Return whether Theta requires a state vector input X.
"""
state_dependent_Theta(m::CevAssetModel) = true  # COV_EXCL_LINE

"""
    state_alias_H(m::CevAssetModel)

Return a list of state alias strings required for (H * X) calculation.
"""
state_alias_H(m::CevAssetModel) = state_alias(m)

"""
    state_dependent_H(m::CevAssetModel)

Return whether H requires a state vector input X.
"""
state_dependent_H(m::CevAssetModel) = false  # COV_EXCL_LINE

"""
    state_alias_Sigma(m::CevAssetModel)

Return a list of state alias strings required for (Sigma(u)' Gamma Sigma(u)) calculation.
"""
state_alias_Sigma(m::CevAssetModel) = state_alias(m::CevAssetModel)

"""
    factor_alias_Sigma(m::CevAssetModel)

Return a list of factor alias strings required for (Sigma(u)^T Gamma Sigma(u)) calculation.
"""
factor_alias_Sigma(m::CevAssetModel) = factor_alias(m)

"""
    state_dependent_Sigma(m::CevAssetModel)

Return whether Sigma requires a state vector input X.
"""
state_dependent_Sigma(m::CevAssetModel) = true  # COV_EXCL_LINE


"""
    asset_volatility(
        m::CevAssetModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a state-independent volatility function sigma(u) for the interval (s,t).
"""
function asset_volatility(
    m::CevAssetModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Sigma(m)
    @assert size(X.X)[2] == 1  # require a single state
    x_s = X(state_alias(m)[1])[1]  # this should be a scalar
    sigma(u) = scalar_volatility(m.sigma_x, u) * exp(scalar_value(m.skew_x, u) * x_s)
    return sigma
end

# Model functions for CEV model duplicate code from LognormalModel.
# Consider refactoring to avoid code duplication.

"""
    Theta(
        m::CevAssetModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the deterministic drift component for simulation over the time period [s, t].
"""
function Theta(
    m::CevAssetModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Theta(m)
    @assert size(X.X)[2] == 1  # require a single state
    sigma = asset_volatility(m, s, t, X)
    # alpha is a vector-valued function
    alpha = quanto_drift(factor_alias(m), m.quanto_model, s, t, X)
    f(u) = sigma(u) * (sigma(u) +  2*alpha(u)[1])
    val = _scalar_integral(f, s, t, parameter_grid(m))
    return [ -0.5 * val ]
end


"""
    H_T(
        m::CevAssetModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the transposed of the convection matrix H for simulation over the time period
[s, t].
"""
function H_T(
    m::CevAssetModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_H(m)
    return ones(1,1)
end


"""
    Sigma_T(
        m::CevAssetModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a matrix-valued function representing the volatility matrix function.

The signature of the resulting function is (u::ModelTime). Here, u represents the
observation time.
"""
function Sigma_T(
    m::CevAssetModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Sigma(m)
    @assert size(X.X)[2] == 1  # require a single state
    sigma = asset_volatility(m, s, t, X)
    f(u) = sigma(u) * ones(1,1)
    return f
end


"""
    log_asset(m::CevAssetModel, model_alias::String, t::ModelTime, X::ModelState)

Retrieve the normalised state variable from an asset model.
"""
function log_asset(m::CevAssetModel, model_alias::String, t::ModelTime, X::ModelState)
    @assert alias(m) == model_alias
    return X(state_alias(m)[1])
end


"""
    simulation_parameters(
        m::CevAssetModel,
        ch::Union{CorrelationHolder, Nothing},
        s::ModelTime,
        t::ModelTime,
        )

Pre-calculate parameters that are used in state-dependent Theta and Sigma calculation.
"""
function simulation_parameters(
    m::CevAssetModel,
    ch::Union{CorrelationHolder, Nothing},
    s::ModelTime,
    t::ModelTime,
    )
    f_sigma(u) = scalar_volatility(m.sigma_x, u)^2
    sigma_av = sqrt(_scalar_integral(f_sigma, s, t, parameter_grid(m)) / (t -s))
    f_skew(u) = scalar_value(m.skew_x, u)
    skew_av = _scalar_integral(f_skew, s, t, parameter_grid(m))  / (t -s)
    return (
        sigma_av = sigma_av,
        skew_av = skew_av,
    )
end


"""
    diagonal_volatility(
        m::CevAssetModel,
        s::ModelTime,
        t::ModelTime,
        X::ModelState,
        )

Calculate the path-dependent volatilities for CevAssetModel.

`X` is supposed to hold a state matrix of size `(n, p)`. Here, `n` is
`length(state_alias(m))` and `p` is the number of paths.

The method returns a matrix of size `(n, p)`.
"""
function diagonal_volatility(
    m::CevAssetModel,
    s::ModelTime,
    t::ModelTime,
    X::ModelState,
    )
    @assert isa(X.params, NamedTuple)
    x_s = X(state_alias(m)[1])  # this is a vector of the x-variable
    vol = X.params.sigma_av * exp.(X.params.skew_av * x_s)
    return reshape(vol, (1,:))
end
