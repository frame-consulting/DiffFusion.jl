
"""
    abstract type CompositeModel <: Model

A `CompositeModel` represents a collection of (coupled) component models.

`CompositeModel`s are supposed to hold the following elements

    alias::String
    models::Tuple
    state_alias
    factor_alias
    model_dict::Dict{String,Int}

For concrete types, see `SimpleModel`.
"""
abstract type CompositeModel <: Model end


"""
    model_alias(m::CompositeModel)

Return the aliases modelled by a model.

Typical this coincides with the model's own alias. For composite models this
is a list of component model aliases.
"""
function model_alias(m::CompositeModel)
    return [ alias(cm) for cm in m.models ]
end

"""
    parameter_grid(m::CompositeModel)

Return a list of times representing the (joint) grid points of piece-wise
constant model parameters.

This method is intended to be used in conjunction with time-integration
mehods that require smooth integrand functions.
"""
function parameter_grid(m::CompositeModel)
    return parameter_grid(m.models)
end

"""
    log_asset(m::CompositeModel, alias::String, t::ModelTime, X::ModelState)

Retrieve the normalised state variable from an asset model.
"""
function log_asset(m::CompositeModel, alias::String, t::ModelTime, X::ModelState)
    return log_asset(m.models[m.model_dict[alias]], alias, t, X)
end

"""
    log_bank_account(m::CompositeModel, alias::String, t::ModelTime, X::ModelState)

Retrieve the integral over sum of state variables s(t) from interest rate model.
"""
function log_bank_account(m::CompositeModel, alias::String, t::ModelTime, X::ModelState)
    return log_bank_account(m.models[m.model_dict[alias]], alias, t, X)
end

"""
    log_zero_bond(m::CompositeModel, alias::String, t::ModelTime, T::ModelTime, X::ModelState)

Calculate the zero bond term [G(t,T)' x(t) + 0.5 G(t,T)' y(t) G(t,T)]' from rates model.
"""
function log_zero_bond(m::CompositeModel, alias::String, t::ModelTime, T::ModelTime, X::ModelState)
    return log_zero_bond(m.models[m.model_dict[alias]], alias, t, T, X)
end

"""
    log_future(m::CompositeModel, alias::String, t::ModelTime, T::ModelTime, X::ModelState)

Calculate the Future price term h(t,T)'[x(t) + 0.5y(t)(1 - h(t,T))].
"""
function log_future(m::CompositeModel, alias::String, t::ModelTime, T::ModelTime, X::ModelState)
    return log_future(m.models[m.model_dict[alias]], alias, t, T, X)
end

"""
    forward_rate_variance(
        m::CompositeModel,
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
    m::CompositeModel,
    alias::String,
    t::ModelTime,
    T::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    )
    #
    return forward_rate_variance(
        m.models[m.model_dict[alias]],
        alias,
        t,
        T,
        T0,
        T1,
    )
end

"""
    state_dependent_Theta(m::CompositeModel)

Return whether Theta requires a state vector input X.
"""
function state_dependent_Theta(m::CompositeModel)
    res = false
    for cm in m.models
        res = res || state_dependent_Theta(cm)
    end
    return res
end

"""
    state_alias_H(m::CompositeModel)

Return a list of state alias strings required for (H * X) calculation.
"""
state_alias_H(m::CompositeModel) = state_alias(m)

"""
    state_dependent_H(m::CompositeModel)

Return whether H requires a state vector input X.
"""
function state_dependent_H(m::CompositeModel)
    res = false
    for cm in m.models
        res = res || state_dependent_H(cm)
    end
    return res
end

"""
    factor_alias_Sigma(m::CompositeModel)

Return a list of factor alias strings required for (Sigma(u)^T Gamma Sigma(u)) calculation.
"""
factor_alias_Sigma(m::CompositeModel) = factor_alias(m)

"""
    state_dependent_Sigma(m::CompositeModel)

Return whether Sigma requires a state vector input X.
"""
function state_dependent_Sigma(m::CompositeModel)
    res = false
    for cm in m.models
        res = res || state_dependent_Sigma(cm)
    end
    return res
end


"""
    _coo_matrix(A::AbstractMatrix, i_offset::Integer = 0, j_offset::Integer = 0)

Return the COO format for a matrix A.

This method is used in `SimpleModel` `H_T(...)` and `Sigma_T(...)` calculation.
"""
function _coo_matrix(A::AbstractMatrix, i_offset::Integer = 0, j_offset::Integer = 0)
    (m, n) = size(A)
    I = vec([ i for i in (1+i_offset):(m+i_offset), j in (1+j_offset):(n+j_offset) ])
    J = vec([ j for i in (1+i_offset):(m+i_offset), j in (1+j_offset):(n+j_offset) ])
    return I, J, vec(A)
end
