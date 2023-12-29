

"""
    abstract type Model end

An abstract base model type. This type covers component models and hybrid composite
models.
"""
abstract type Model end

"""
    abstract type ComponentModel <: Model end

An abstract component model type. This type implements the common interface of all
component models.
"""
abstract type ComponentModel <: Model end

"""
    alias(m::Model)

Return the model's own alias. This is the default implementation.
"""
function alias(m::Model)
    return m.alias
end

"""
    model_alias(m::Model)

Return the aliases modelled by a model.

Typically, this coincides with the model's own alias. For composite models this
is a list of component model aliases.
"""
function model_alias(m::Model)
    return [ alias(m) ]  # default implementation
end

"""
    state_alias(m::Model)

Return a list of state alias strings that represent the model components.
"""
function state_alias(m::Model)
    return m.state_alias
end

"""
    factor_alias(m::Model)

Return a list of risk factor alias strings that represent the components of the
multi-variate Brownian motion risk factors. 
"""
function factor_alias(m::Model)
    return m.factor_alias
end

"""
    parameter_grid(m::Model)

Return a list of times representing the (joint) grid points of piece-wise
constant model parameters.

This method is intended to be used in conjunction with time-integration
mehods that require smooth integrand functions.
"""
function parameter_grid(m::Model)
    return []  # default implementation
end


"""
    parameter_grid(models::AbstractVector)

Return a list of times representing the (joint) grid points of piece-wise
constant model parameters.

This method is intended to be used in conjunction with time-integration
mehods that require smooth integrand functions.
"""
function parameter_grid(models::Union{AbstractVector, Tuple})
    return sort(union([ parameter_grid(m) for m in models ]...))
end


"""
    struct ModelState
        X::AbstractMatrix
        idx::Dict{String,Int}
    end

A ModelState is a matrix of state variables decorated by a dictionary of alias
strings and optional additional parameters.

It allows to decouple simulation of state variables and usage of state variables.

`X` is of size (n, p) where n represents the number of state aliases and p represents the
number of paths. A matrix with a large number of paths is typically used when calling
model functions for payoff evaluation.

A single realisation of risk factors is represented by an (n, 1) matrix. We use (n,1)
matrix instead of (n,) vector to avoid size-dependent switches.

`idx` is a dictionary with n entries. Keys represent state state alias entries and
values represent the corresponding positions in `X`.

`params` is a struct or dictionary that holds additional pre-calculated state-independent
data which is used in subsequent Theta and Sigma calculations. This aims at avoiding
duplicate calculations for state-dependent Theta and Sigma calculations. The `params`
is supposed to be calculated by method `simulation_parameters(...)`.
"""
struct ModelState
    X::AbstractMatrix
    idx::Dict{String,Int}
    params::Any
end

const _model_state_extra_safety_check = false

"""
    model_state(X::AbstractMatrix, idx::Dict{String,Int})

Create a ModelState object and make sure it is consistent.
"""
function model_state(X::AbstractMatrix, idx::Dict{String,Int}, params = nothing)
    @assert size(X)[1] == length(idx)
    if _model_state_extra_safety_check
        values = sort([ v for (k,v) in idx ])
        for k in 1:length(values)
            @assert values[k] == k
        end
    end
    return ModelState(X, idx, params)
end

"""
    model_state(X::AbstractMatrix, m::Model, params = nothing)

Create a model state for a given model.
"""
function model_state(X::AbstractMatrix, m::Model, params = nothing)
    idx = alias_dictionary(state_alias(m))
    return model_state(X, idx, params)
end

"""
    (V::ModelState)(alias::String)

Allow for indexed access to ModelState via alias
"""
(V::ModelState)(alias::String) = @view(V.X[V.idx[alias],:])

"""
    alias_dictionary(alias_list)

Create an alias dictionary
"""
alias_dictionary(alias_list) = Dict([(e,k) for (k,e) in enumerate(alias_list)])

"""
    log_asset(m::Model, alias::String, t::ModelTime, X::ModelState)

Retrieve the normalised state variable from an asset model.

Returns a vector of size (p,) for X with size (n,p).
"""
function log_asset(m::Model, alias::String, t::ModelTime, X::ModelState)
    error("Model needs to implement log_asset method.")
end

"""
    log_bank_account(m::Model, alias::String, t::ModelTime, X::ModelState)

Retrieve the integral over sum of state variables s(t) from interest rate model.

Returns a vector of size (p,) for X with size (n,p).
"""
function log_bank_account(m::Model, alias::String, t::ModelTime, X::ModelState)
    error("Model needs to implement log_bank_account method.")
end

"""
    log_zero_bond(m::Model, alias::String, t::ModelTime, T::ModelTime, X::ModelState)

Calculate the zero bond term [G(t,T)' x(t) + 0.5 G(t,T)' y(t) G(t,T)]' from rates model.

Returns a vector of size (p,) for X with size (n,p).
"""
function log_zero_bond(m::Model, alias::String, t::ModelTime, T::ModelTime, X::ModelState)
    error("Model needs to implement log_compounding_factor method.")
end

"""
    log_compounding_factor(
        m::Model,
        model_alias::String,
        t::ModelTime,
        T1::ModelTime,
        T2::ModelTime,
        X::ModelState,
        )

Calculate the forward compounding factor term
[G(t,T2) - G(t,T1)]' x(t) + 0.5 * [G(t,T2)' y(t) G(t,T2) - G(t,T1)' y(t) G(t,T1)].

This is used for Libor forward rate calculation.

Returns a vector of size (p,) for X with size (n,p).
"""
function log_compounding_factor(
    m::Model,
    model_alias::String,
    t::ModelTime,
    T1::ModelTime,
    T2::ModelTime,
    X::ModelState,
    )
    #
    error("Model needs to implement log_compounding_factor method.")
end

"""
    log_asset_convexity_adjustment(
        m::Model,
        dom_alias::String,
        for_alias::String,
        ast_alias::String,
        t::ModelTime,
        T0::ModelTime,
        T1::ModelTime,
        T2::ModelTime,
        )

Calculate the YoY convexity adjustment term for OU models.

Returns a scalar quantity.
"""
function log_asset_convexity_adjustment(
    m::Model,
    dom_alias::String,
    for_alias::String,
    ast_alias::String,
    t::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    T2::ModelTime,
    )
    error("Model needs to implement log_asset_convexity_adjustment method.")
end

"""
    log_future(m::Model, alias::String, t::ModelTime, T::ModelTime, X::ModelState)

Calculate the Future price term h(t,T)'[x(t) + 0.5y(t)(1 - h(t,T))].
"""
function log_future(m::Model, alias::String, t::ModelTime, T::ModelTime, X::ModelState)
    error("Model needs to implement log_future method.")
end

"""
    swap_rate_variance(
        m::Model,
        alias::String,
        yts::YieldTermstructure,
        t::ModelTime,
        T::ModelTime,
        swap_times::AbstractVector,
        yf_weights::AbstractVector,
        X::ModelState,
        )

Calculate the normal model variance of a swap rate via Gaussian
swap rate approximation.
"""
function swap_rate_variance(
    m::Model,
    alias::String,
    yts::YieldTermstructure,
    t::ModelTime,
    T::ModelTime,
    swap_times::AbstractVector,
    yf_weights::AbstractVector,
    X::ModelState,
    )
    error("Model needs to implement swap_rate_variance method.")
end

"""
    forward_rate_variance(
        m::Model,
        alias::String,
        t::ModelTime,
        T::ModelTime,
        T0::ModelTime,
        T1::ModelTime,
        )

Calculate the lognormal variance for a compounding factor of a forward-looking
or backward-looking forward rate.
"""
function forward_rate_variance(
    m::Model,
    alias::String,
    t::ModelTime,
    T::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    )
    error("Model needs to implement forward_rate_variance method.")
end

"""
    asset_variance(
        m::Model,
        ast_alias::Union{String, Nothing},
        dom_alias::Union{String, Nothing},
        for_alias::Union{String, Nothing},
        t::ModelTime,
        T::ModelTime,
        X::ModelState,
        )

Calculate the lognormal model variance of an asset spot price
over the time period [t,T]. If Model is state-dependent then
variance calculation takes into account model state X.
"""
function asset_variance(
    m::Model,
    ast_alias::Union{String, Nothing},
    dom_alias::Union{String, Nothing},
    for_alias::Union{String, Nothing},
    t::ModelTime,
    T::ModelTime,
    X::ModelState,
    )
    error("Model needs to implement asset_variance method.")
end

"""
    Theta(
        m::Model,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the deterministic drift component for simulation over the time period [s, t].
If Theta is state-dependent a state vector `X` must be supplied. The method returns a
vector of `length(state_alias)`.
"""
function Theta(
    m::Model,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    error("Model needs to implement Theta method.")
end

"""
    state_dependent_Theta(m::Model)

Return whether Theta requires a state vector input `X`.
"""
function state_dependent_Theta(m::Model)
    error("Model needs to implement state_dependent_Theta method.")
end

"""
    H_T(
        m::Model,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the transposed of the convection matrix H for simulation over the time period
[s, t].
If H is state-dependent a state vector `X` must be supplied.
We use the transposed of H to
 - allow for efficient sparse CSC matrix insertion and
 - allow for efficient multiplication X' * H' = (H * X)'.
The state vector `X` may effectively be a subset of all states. To accommodate this, we
use a dedicated list of state aliases `state_alias_H` for the result matrix.
The method returns a (sparse) matrix of size `(length(state_alias_H), length(state_alias))`.
"""
function H_T(
    m::Model,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    error("Model needs to implement H_T method.")
end

"""
    state_alias_H(m::Model)

Return a list of state alias strings required for (H * X) calculation.
"""
function state_alias_H(m::Model)
    error("Model needs to implement state_alias_H method.")
end

"""
    state_dependent_H(m::Model)

Return whether H requires a state vector input `X`.
"""
function state_dependent_H(m::Model)
    error("Model needs to implement state_dependent_H method.")
end

"""
    Sigma_T(
        m::Model,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a matrix-valued function representing the volatility matrix function.

The signature of the resulting function is `(u::ModelTime)`. Here, `u` represents the
observation time.

The state vector is required if Sigma(u) depends on X_s.
    
The result of an evaluation of `Sigma_T(...)(u)` is a matrix of size
`(length(state_alias), length(factor_alias_Sigma))`.

The Brownian motion relevant for a model may effectively be a subset of all Brownian
motions. To accommodate this, we use a dedicated list of factor aliases
`factor_alias_Sigma` for the size of the result matrix of a function evaluation.

The transposed '_T' is convention to simplify notation for covariance calculation.
"""
function Sigma_T(
    m::Model,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    error("Model needs to implement Sigma_T method.")
end

"""
    factor_alias_Sigma(m::Model)

Return a list of factor alias strings required for (Sigma(u)' Gamma Sigma(u)) calculation.
"""
function factor_alias_Sigma(m::Model)
    error("Model needs to implement factor_alias_Sigma method.")
end

"""
    state_dependent_Sigma(m::Model)

Return whether Sigma requires a state vector input `X`.
"""
function state_dependent_Sigma(m::Model)
    error("Model needs to implement state_dependent_Sigma method.")
end

"""
    covariance(
        m::Model,
        ch::Union{CorrelationHolder, Nothing},
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Calculate the covariance matrix over a time interval.
"""
function covariance(
    m::Model,
    ch::Union{CorrelationHolder, Nothing},
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    if isnothing(ch)
        Gamma = Diagonal(ones(length(factor_alias(m))))
    else
        Gamma = ch(factor_alias(m))
    end
    d = length(state_alias(m))
    f(u) = vec(Sigma_T(m,s,t,X)(u) * Gamma * Sigma_T(m,s,t,X)(u)')
    cov_vec = _vector_integral(f, s, t, parameter_grid(m))
    cov = reshape(cov_vec, (d,d))
    return cov
end

"""
    volatility_and_correlation(
        m::Model,
        ch::Union{CorrelationHolder, Nothing},
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        vol_eps::ModelValue = 1.0e-8,  # avoid division by zero
        )

Calculate the volatility vector and correlation matrix over a time interval.
"""
function volatility_and_correlation(
    m::Model,
    ch::Union{CorrelationHolder, Nothing},
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    vol_eps::ModelValue = 1.0e-8,  # avoid division by zero
    )
    d = length(state_alias(m))
    cov = covariance(m,ch,s,t,X)
    vol = sqrt.([ cov[i,i] for i in 1:d ] * (1.0/(t-s) ))
    #
    corr_(i,j) = begin
        if i<j
            return corr_(j,i) # ensure symmetry
        end
        if i==j
            return 1.0 + 0.0 * cov[i,j]  # ensure type-stability
        end
        # i > j
        if (vol[i]>vol_eps) && (vol[j]>vol_eps)
            return cov[i,j] / vol[i] / vol[j] / (t-s)
        end
        return 0.0 * cov[i,j]  # ensure type-stability
    end
    corr = [ corr_(i,j) for i in 1:d, j in 1:d ]
    return (vol, corr)
end

"""
    simulation_parameters(
        m::Model,
        ch::Union{CorrelationHolder, Nothing},
        s::ModelTime,
        t::ModelTime,
        )

Pre-calculate parameters that are used in state-dependent Theta and Sigma calculation.
"""
function simulation_parameters(
    m::Model,
    ch::Union{CorrelationHolder, Nothing},
    s::ModelTime,
    t::ModelTime,
    )
    error("Model needs to implement simulation_parameters method.")
end

"""
    diagonal_volatility(
        m::Model,
        s::ModelTime,
        t::ModelTime,
        X::ModelState,
        )

Calculate the path-dependent volatilities for a given model.

`X` is supposed to hold a state matrix of size `(n, p)`. Here, `n` is
`length(state_alias(m))` and `p` is the number of paths.

The method returns a matrix of size `(n, p)`.
"""
function diagonal_volatility(
    m::Model,
    s::ModelTime,
    t::ModelTime,
    X::ModelState,
    )
    error("Model needs to implement diagonal_volatility method.")
end
