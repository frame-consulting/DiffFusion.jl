
"""
    struct LognormalAssetModel <: AssetModel
        alias::String
        sigma_x::BackwardFlatVolatility
        state_alias::AbstractVector
        factor_alias::AbstractVector
        correlation_holder::CorrelationHolder
        quanto_model::Union{AssetModel, Nothing}
    end

A `LognormalAssetModel` is a model for simulating a spot price in a
generalised Black-Scholes framework.
"""
struct LognormalAssetModel <: AssetModel
    alias::String
    sigma_x::BackwardFlatVolatility
    state_alias::AbstractVector
    factor_alias::AbstractVector
    correlation_holder::CorrelationHolder
    quanto_model::Union{AssetModel, Nothing}
end

"""
    lognormal_asset_model(
        alias::String,
        sigma_x::BackwardFlatVolatility,
        ch::CorrelationHolder,
        quanto_model::Union{AssetModel, Nothing}
        )

Create a LognormalAssetModel.
"""
function lognormal_asset_model(
    alias::String,
    sigma_x::BackwardFlatVolatility,
    ch::CorrelationHolder,
    quanto_model::Union{AssetModel, Nothing}
    )
    @assert size(sigma_x.values)[1] == 1
    state_alias = [ alias * "_x" ]
    factor_alias = [ alias * "_x" ]
    return LognormalAssetModel(alias, sigma_x, state_alias, factor_alias, ch, quanto_model)
end

"""
    parameter_grid(m::LognormalAssetModel)

Return a list of times representing the (joint) grid points of piece-wise
constant model parameters.

This method is intended to be used in conjunction with time-integration
mehods that require smooth integrand functions.
"""
function parameter_grid(m::LognormalAssetModel)
    return m.sigma_x.times
end

"""
    state_dependent_Theta(m::LognormalAssetModel)

Return whether Theta requires a state vector input X.
"""
state_dependent_Theta(m::LognormalAssetModel) = 
    (isnothing(m.quanto_model)) ? false : state_dependent_Sigma(m.quanto_model)

"""
    state_alias_H(m::LognormalAssetModel)

Return a list of state alias strings required for (H * X) calculation.
"""
state_alias_H(m::LognormalAssetModel) = state_alias(m)

"""
    state_dependent_H(m::LognormalAssetModel)

Return whether H requires a state vector input X.
"""
state_dependent_H(m::LognormalAssetModel) = false

"""
    factor_alias_Sigma(m::LognormalAssetModel)

Return a list of factor alias strings required for (Sigma(u)^T Gamma Sigma(u)) calculation.
"""
factor_alias_Sigma(m::LognormalAssetModel) = factor_alias(m)

"""
    state_dependent_Sigma(m::LognormalAssetModel)

Return whether Sigma requires a state vector input X.
"""
state_dependent_Sigma(m::LognormalAssetModel) = false

"""
    asset_volatility(
        m::LognormalAssetModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a state-independent volatility function sigma(u) for the interval (s,t).
"""
function asset_volatility(
    m::LognormalAssetModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Sigma(m)
    sigma(u) = m.sigma_x(u, TermstructureScalar)
    return sigma
end


"""
    Theta(
        m::LognormalAssetModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the deterministic drift component for simulation over the time period [s, t].
"""
function Theta(
    m::LognormalAssetModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Theta(m)
    # alpha is a vector-valued function
    alpha = quanto_drift(factor_alias(m), m.quanto_model, s, t, X)
    # 'TermstructureScalar' yields scalar volatility
    f(u) = m.sigma_x(u,TermstructureScalar)*(m.sigma_x(u,TermstructureScalar) + 2*alpha(u)[1])
    val = _scalar_integral(f, s, t, parameter_grid(m))
    return [ -0.5 * val ]
end


"""
    H_T(
        m::LognormalAssetModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the transposed of the convection matrix H for simulation over the time period
[s, t].
"""
function H_T(
    m::LognormalAssetModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_H(m)
    return ones(1,1)
end


"""
    Sigma_T(
        m::LognormalAssetModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a matrix-valued function representing the volatility matrix function.

The signature of the resulting function is (u::ModelTime). Here, u represents the
observation time.
"""
function Sigma_T(
    m::LognormalAssetModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Sigma(m)
    f(u) = m.sigma_x(u, TermstructureScalar) * ones(1,1)
    return f
end


"""
    log_asset(m::LognormalAssetModel, model_alias::String, t::ModelTime, X::ModelState)

Retrieve the normalised state variable from an asset model.
"""
function log_asset(m::LognormalAssetModel, model_alias::String, t::ModelTime, X::ModelState)
    @assert alias(m) == model_alias
    return X(state_alias(m)[1])
end


"""
    simulation_parameters(
        m::LognormalAssetModel,
        ch::Union{CorrelationHolder, Nothing},
        s::ModelTime,
        t::ModelTime,
        )

Pre-calculate parameters that are used in state-dependent Theta and Sigma calculation.

For LognormalAssetModel there are no valuations that should be cached.
"""
function simulation_parameters(
    m::LognormalAssetModel,
    ch::Union{CorrelationHolder, Nothing},
    s::ModelTime,
    t::ModelTime,
    )
    #
    return nothing
end
