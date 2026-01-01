
"""
    struct QuasiGaussianModel <: SeparableHjmModel
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

QuasiGaussianModel model generalises GaussianHjmModel.
"""
struct QuasiGaussianModel{
        ModelType<:GaussianHjmModel,
        SkewType<:ModelValue,
        VolModelType<:Union{ComponentModel, Nothing},
    } <: SeparableHjmModel
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
    quasi_gaussian_model(
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
function quasi_gaussian_model(
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
    return QuasiGaussianModel(
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
    quasi_gaussian_model(
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
function quasi_gaussian_model(
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
    return quasi_gaussian_model(
        gaussian_model,
        slope_d,
        slope_u,
        sigma_min,
        sigma_max,
        volatility_model,
        volatility_function,
    )
end


# Model interface

"""
    alias(m::QuasiGaussianModel)

Return the model's own alias.
"""
alias(m::QuasiGaussianModel) = alias(m.gaussian_model)

"""
    parameter_grid(m::QuasiGaussianModel)

Return a list of times representing the (joint) grid points of piece-wise
constant model parameters.
"""
parameter_grid(m::QuasiGaussianModel) = parameter_grid(m.gaussian_model)

"""
    state_dependent_Theta(m::QuasiGaussianModel)

Return whether Theta requires a state vector input X.
"""
state_dependent_Theta(m::QuasiGaussianModel) = true  # COV_EXCL_LINE

"""
    state_alias_H(m::QuasiGaussianModel)

Return a list of state alias strings required for (H * X) calculation.
"""
state_alias_H(m::QuasiGaussianModel) = state_alias(m)

"""
    state_dependent_H(m::QuasiGaussianModel)

Return whether H requires a state vector input X.
"""
state_dependent_H(m::QuasiGaussianModel) = false  # COV_EXCL_LINE

"""
    state_alias_Sigma(m::QuasiGaussianModel)

Return a list of state alias strings required for (Sigma(u)' Gamma Sigma(u)) calculation.

Note, auxiliary variable `y` is *not* included here.
"""
state_alias_Sigma(m::QuasiGaussianModel) = state_alias_Sigma(m.gaussian_model)

"""
Return a list of factor alias strings required for (Sigma(u)^T Gamma Sigma(u)) calculation.
"""
factor_alias_Sigma(m::QuasiGaussianModel) = factor_alias(m)

"""
Return whether Sigma requires a state vector input X.
"""
state_dependent_Sigma(m::QuasiGaussianModel) = true  # COV_EXCL_LINE


# Modelled variables

"""
    state_variable(
        m::QuasiGaussianModel,
        X::ModelState,
        )

Extract the quasi-Gaussian state variable `x` from `ModelState`.
"""
function state_variable(
    m::QuasiGaussianModel,
    X::ModelState,
    )
    #
    idx = X.idx[state_alias(m)[begin]]
    d = length(state_alias(m.gaussian_model)) - 1  # exclude s-variable
    return @view(X.X[idx:idx+(d-1),:])  # as (d, p) matrix
end

"""
    integrated_state_variable(
        m::QuasiGaussianModel,
        X::ModelState,
        )

Extract the integrated state variable `s` from `ModelState`.
"""
function integrated_state_variable(
    m::QuasiGaussianModel,
    X::ModelState,
    )
    #
    s_alias = state_alias(m.gaussian_model)[end]
    idx = X.idx[s_alias]
    return @view(X.X[idx:idx,:])   # as (1, p) matrix
end

"""
    auxiliary_variable(
        m::QuasiGaussianModel,
        X::ModelState,
        )

Extract the quasi-Gaussian auxiliary variable `y` from `ModelState`.
"""
function auxiliary_variable(
    m::QuasiGaussianModel,
    X::ModelState,
    )
    #
    idx = X.idx[state_alias(m)[1]]
    d = length(state_alias(m.gaussian_model)) - 1  # exclude s-variable
    idx += (d + 1)  # skip x and s variable
    y_vec = @view(X.X[idx:idx+(d*d-1),:])
    reshape(y_vec, (d, d, :))
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
    return gamma
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
        m::QuasiGaussianModel,
        s::ModelTime,
        t::ModelTime,
        X::ModelState,
        )

Calculate the benchmark-rate local/stochastic volatility for the interval
(s, t).

This method assumes that local volatility is constant on the interval (s, t).
"""
function func_sigma_f(
    m::QuasiGaussianModel,
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
    #
    return min.(max.(gamma .* (sigma_0 .+ slope_d .* X_d .+ slope_u .* X_u), m.sigma_min), m.sigma_max)
end

"""
    func_sigma_T(
        m::QuasiGaussianModel,
        sigma_f::AbstractVector,
        )

Calculate the state variable volatility function.
"""
function func_sigma_T(
    m::QuasiGaussianModel,
    sigma_f::AbstractVector,
    )
    #
    v = m.gaussian_model.sigma_T
    d = length(sigma_f)
    return [
        sum( v.scaling_matrix[i,k] * v.DfT[k,j] * sigma_f[k] for k = 1:d )
        for i = 1:d, j = 1:d
    ]
end

"""
    func_sigma_T_hyb(
        m::QuasiGaussianModel,
        sigma_f::AbstractVector,
        )

Calculate the state variable volatility function for the hybrid model interface.
"""
function func_sigma_T_hyb(
    m::QuasiGaussianModel,
    sigma_f::AbstractVector,
    )
    #
    v = m.gaussian_model.sigma_T
    return v.scaling_matrix .* reshape(sigma_f, (1,:))
end

"""
A `HjmAuxiliaryVariable` functor for `QuasiGaussianModel`.
"""
struct QuasiGaussianAuxiliaryVariable{
        T1<:ModelValue,
        T2<:ModelValue,
        T3<:ModelValue,
    } <: HjmAuxiliaryVariable
    #
    y0::Matrix{T1}
    chi::Vector{T2}
    sigmaT::Matrix{T3}
    t0::ModelTime
end

"""
Evaluate `QuasiGaussianAuxiliaryVariable` at time `t`.
"""
(v::QuasiGaussianAuxiliaryVariable)(t::ModelTime) = func_y(v.y0, v.chi, v.sigmaT, v.t0, t)


"""
A `HjmHybridVolatility` for a `QuasiGaussianModel`.
"""
struct QuasiGaussianHybridVolatility{T1<:QuasiGaussianModel, T2<:ModelValue} <: HjmHybridVolatility
    m::T1
    sigma_f::Vector{T2}
end

"""
Evaluate `QuasiGaussianHybridVolatility` at time `t`.
"""
(v::QuasiGaussianHybridVolatility)(t::ModelTime) = func_sigma_T_hyb(v.m, v.sigma_f)


"""
    Theta(
        m::QuasiGaussianModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the deterministic drift component for simulation over the time period [s, t] and
using the state vector `X`.

Method returns a vector of length(state_alias).
"""
function Theta(
    m::QuasiGaussianModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Theta(m)
    @assert size(X.X)[2] == 1  # require a single state
    @assert s ≤ t
    # note, we cannot calculate y(u) if sigma_f changes
    sigma_f = vec(func_sigma_f(m, s, t, X))
    #
    y0 = auxiliary_variable(m, X)[:,:,1]
    chi = m.gaussian_model.chi()
    sigma_T = func_sigma_T(m, sigma_f)
    y = QuasiGaussianAuxiliaryVariable(y0, chi, sigma_T, s)
    # make sure we do not apply correlations twice in quanto adjustment!
    sigma_T_hyb = QuasiGaussianHybridVolatility(m, sigma_f)
    # take into account quanto adjustment
    qm = m.gaussian_model.quanto_model
    if !isnothing(qm) && state_dependent_Sigma(qm)
        alpha = quanto_drift(m.gaussian_model.factor_alias, qm, s, t, X)
    else
        alpha = quanto_drift(m.gaussian_model.factor_alias, qm, s, t, nothing)
    end
    return vcat(
        func_Theta_x_integrate_y(chi, y, sigma_T_hyb, alpha, s, t, parameter_grid(m)),
        func_Theta_s(chi, y, sigma_T_hyb, alpha, s, t, parameter_grid(m)),
        vec(y(t)),
    )
end


"""
    H_T(
        m::QuasiGaussianModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the transposed of the convection matrix H for simulation over the time period
[s, t].
"""
function H_T(
    m::QuasiGaussianModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_H(m)
    H_T_gaussian = func_H_T(m.gaussian_model.chi(), s, t)
    M = length(state_alias_H(m))
    return sparse(findnz(H_T_gaussian)..., M, M)
end


"""
    Sigma_T(
        m::QuasiGaussianModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a matrix-valued function representing the volatility matrix function.
"""
function Sigma_T(
    m::QuasiGaussianModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Sigma(m)
    @assert size(X.X)[2] == 1  # require a single state
    @assert s ≤ t
    # note, we cannot sigma_T if sigma_f changes
    sigma_f = vec(func_sigma_f(m, s, t, X))
    # make sure we do not apply correlations twice!
    sigma_T_hyb = QuasiGaussianHybridVolatility(m, sigma_f)
    return func_Sigma_T(m.gaussian_model.chi(), sigma_T_hyb, s, t)
end


"""
    simulation_parameters(
        m::QuasiGaussianModel,
        ch::Union{CorrelationHolder, Nothing},
        s::ModelTime,
        t::ModelTime,
        )

Pre-calculate parameters that are used in state-dependent Theta and Sigma calculation.

For QuasiGaussianModel there are no valuations that should be cached.
"""
function simulation_parameters(
    m::QuasiGaussianModel,
    ch::Union{CorrelationHolder, Nothing},
    s::ModelTime,
    t::ModelTime,
    )
    #
    return nothing
end


"""
    log_bank_account(m::QuasiGaussianModel, model_alias::String, t::ModelTime, X::ModelState)

Retrieve the integral over sum of state variables s(t) from interest rate model.
"""
function log_bank_account(m::QuasiGaussianModel, model_alias::String, t::ModelTime, X::ModelState)
    @assert alias(m) == model_alias
    return vec(integrated_state_variable(m, X))
end

function _func_GyG(G::AbstractVector, y::AbstractArray)
    return [
        sum(G[i] * sum(y[i,j,p] * G[j] for j in axes(y, 2)) for i in axes(y, 1))
        for p in axes(y, 3)
    ]
end

"""
    log_zero_bond(m::QuasiGaussianModel, model_alias::String, t::ModelTime, T::ModelTime, X::ModelState)

Calculate the zero bond term [G(t,T)' x(t) + 0.5 G(t,T)' y(t) G(t,T)]' from rates model.
"""
function log_zero_bond(m::QuasiGaussianModel, model_alias::String, t::ModelTime, T::ModelTime, X::ModelState)
    @assert alias(m) == model_alias
    #
    G = G_hjm(m.gaussian_model, t, T) # (d,) vector
    X_ = state_variable(m, X)      # (d, p) matrix
    Y_ = auxiliary_variable(m, X)  # (d, d, p) array
    #
    GyG = _func_GyG(G, Y_)  # (p,) vector
    #
    return X_' * G .+ (0.5 .* GyG)
end

"""
    log_zero_bonds(m::QuasiGaussianModel, model_alias::String, t::ModelTime, T::AbstractVector, X::ModelState)

Calculate the zero bond terms [G(t,T)' x(t) + 0.5 G(t,T)' y(t) G(t,T)]' from rates model.
"""
function log_zero_bonds(m::QuasiGaussianModel, model_alias::String, t::ModelTime, T::AbstractVector, X::ModelState)
    @assert alias(m) == model_alias
    #
    G = G_hjm(m.gaussian_model, t, T)  # (d, m) matrix with m = length(T)
    X_ = state_variable(m, X)      # (d, p) matrix
    Y_ = auxiliary_variable(m, X)  # (d, d, p) array
    #
    GyG = hcat([
        _func_GyG(@view(G[:, k]), Y_) for k in axes(G, 2)
    ]...)  # (p, m) matrix
    #
    return X_' * G .+ (0.5 .* GyG)
end

"""
    log_compounding_factor(
        m::QuasiGaussianModel,
        model_alias::String,
        t::ModelTime,
        T1::ModelTime,
        T2::ModelTime,
        X::ModelState,
        )

Calculate the forward compounding factor term
[G(t,T2) - G(t,T1)]' x(t) + 0.5 * [G(t,T2)' y(t) G(t,T2) - G(t,T1)' y(t) G(t,T1)].

This is used for Libor forward rate calculation.
"""
function log_compounding_factor(
    m::QuasiGaussianModel,
    model_alias::String,
    t::ModelTime,
    T1::ModelTime,
    T2::ModelTime,
    X::ModelState,
    )
    #
    @assert alias(m) == model_alias
    #
    G1 = G_hjm(m.gaussian_model, t, T1)  # (d,) vector
    G2 = G_hjm(m.gaussian_model, t, T2)
    #
    X_ = state_variable(m, X)      # (d, p) matrix
    Y_ = auxiliary_variable(m, X)  # (d, d, p) array
    #
    G1yG1 = _func_GyG(G1, Y_)  # (p,) vector
    G2yG2 = _func_GyG(G2, Y_)  # (p,) vector
    #
    return X_' * (G2 .- G1) .+ (0.5 .* (G2yG2 .- G1yG1))
end
