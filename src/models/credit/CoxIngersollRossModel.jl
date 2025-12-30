

"""
A Cox-Ingersoll-Ross model with constant parameters.
"""
struct CoxIngersollRossModel{T<:ModelValue} <: ComponentModel
    alias::String
    params::BackwardFlatParameter{T}  # (z0, chi, theta, sigma)
    state_alias::Vector{String}
    factor_alias::Vector{String}
end

"""
Create a CoxIngersollRossModel.
"""
function cox_ingersoll_ross_model(
    alias::String,
    params::ParameterTermstructure,
    )
    #
    @assert size(params.values) == (4,1)
    @assert params()[1] > 0.0  # z0
    @assert params()[2] > 0.0  # chi
    @assert params()[3] > 0.0  # theta
    @assert params()[4] > 0.0  # sigma
    state_alias = [ alias * "_x" ]
    factor_alias = [ alias * "_x" ]
    return CoxIngersollRossModel(alias, params, state_alias, factor_alias)
end

"""
Create a CoxIngersollRossModel from parameter vector.
"""
function cox_ingersoll_ross_model(
    alias::String,
    param_vector::AbstractVector,
    )
    #
    return cox_ingersoll_ross_model(alias, flat_parameter(param_vector))
end

"""
Create a CoxIngersollRossModel from scalar parameters.
"""
function cox_ingersoll_ross_model(
    alias::String,
    z0::ModelValue,
    chi::ModelValue,
    theta::ModelValue,
    sigma::ModelValue,
    )
    #
    return cox_ingersoll_ross_model(alias, [z0, chi, theta, sigma])
end


"Return z0 parameter."
cir_z0(m::CoxIngersollRossModel) = m.params()[1]

"Return chi parameter."
cir_chi(m::CoxIngersollRossModel) = m.params()[2]

"Return theta parameter."
cir_theta(m::CoxIngersollRossModel) = m.params()[3]

"Return sigma parameter."
cir_sigma(m::CoxIngersollRossModel) = m.params()[4]


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
    m::CoxIngersollRossModel,
    ch::Union{CorrelationHolder, Nothing},
    s::ModelTime,
    t::ModelTime,
    )
    exp_m_chi_dt = exp(-cir_chi(m)*(t-s))
    one_m_exp = 1.0 - exp_m_chi_dt
    sig2_over_chi = cir_sigma(m)^2 / cir_chi(m)
    fac1 = sig2_over_chi * exp_m_chi_dt * one_m_exp
    fac2 = cir_theta(m) * sig2_over_chi / 2.0 * one_m_exp^2
    return (
        exp_m_chi_dt = exp_m_chi_dt,
        one_m_exp = one_m_exp,
        fac1 = fac1,
        fac2 = fac2,
    )
end

"Return first and second moments E[z_t | z_s] and Var[z_t | z_s]."
function cir_moments(
    m::CoxIngersollRossModel,
    zs::Union{ModelValue,AbstractVector}, # allow vectorise via paths
    p::NamedTuple,
    )
    #
    E_zt = zs .* p.exp_m_chi_dt .+ cir_theta(m) * p.one_m_exp
    V_zt = zs .* p.fac1 .+ p.fac2
    return (E_zt, V_zt)
end

"Return first and second moments E[z_t | z_s] and Var[z_t | z_s]."
function cir_moments(
    m::CoxIngersollRossModel,
    zs::Union{ModelValue,AbstractVector}, # allow vectorise via paths
    s::ModelTime,
    t::ModelTime,
    )
    #
    return cir_moments(m, zs, simulation_parameters(m, nothing, s, t))
end

"Calculate lognormal approximation in CIR model."
function cir_lognormal_approximation(
    m::CoxIngersollRossModel,
    zs::Union{ModelValue,AbstractVector}, # vectorise via paths
    p::NamedTuple,
    )
    #
    (μ, ν²) = cir_moments(m, zs, p)
    b2 = log.(1.0 .+ ν² ./ μ.^2)
    a = log.(μ) .- b2 / 2
    return (a, b2)
end

"Calculate lognormal approximation in CIR model."
function cir_lognormal_approximation(
    m::CoxIngersollRossModel,
    zs::Union{ModelValue,AbstractVector}, # allow vectorise via paths
    s::ModelTime,
    t::ModelTime,
    )
    #
    (μ, ν²) = cir_moments(m, zs, s, t)
    b2 = log.(1.0 .+ ν² ./ μ.^2)
    a = log.(μ) .- b2 / 2
    return (a, b2)
end

"Calculate deterministic drift and diffusion component."
function func_Theta_Sigma(
    m::CoxIngersollRossModel,
    zs::Union{ModelValue,AbstractVector}, # allow vectorise via paths
    s::ModelTime,
    t::ModelTime,
    )
    #
    (a, b2) = cir_lognormal_approximation(m,zs,s,t)
    Θ_x = a .- log(cir_z0(m))
    Σ_x = sqrt.(b2 ./ (t-s))
    return (Θ_x, Σ_x)
end


# Model interface

"""
    state_dependent_Theta(m::CoxIngersollRossModel)

Return whether Theta requires a state vector input X.
"""
state_dependent_Theta(m::CoxIngersollRossModel) = true  # COV_EXCL_LINE

"""
    state_alias_H(m::CoxIngersollRossModel)

Return a list of state alias strings required for (H * X) calculation.
"""
state_alias_H(m::CoxIngersollRossModel) = state_alias(m)

"""
    state_dependent_H(m::CoxIngersollRossModel)

Return whether H requires a state vector input X.
"""
state_dependent_H(m::CoxIngersollRossModel) = false  # COV_EXCL_LINE

"""
    state_alias_Sigma(m::CoxIngersollRossModel)

Return a list of state alias strings required for (Sigma(u)' Gamma Sigma(u)) calculation.
"""
state_alias_Sigma(m::CoxIngersollRossModel) = state_alias(m::CoxIngersollRossModel)

"""
    factor_alias_Sigma(m::CoxIngersollRossModel)

Return a list of factor alias strings required for (Sigma(u)^T Gamma Sigma(u)) calculation.
"""
factor_alias_Sigma(m::CoxIngersollRossModel) = factor_alias(m)

"""
    state_dependent_Sigma(m::CoxIngersollRossModel)

Return whether Sigma requires a state vector input X.
"""
state_dependent_Sigma(m::CoxIngersollRossModel) = true  # COV_EXCL_LINE


"""
    Theta(
        m::CoxIngersollRossModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the deterministic drift component for simulation over the time period [s, t].
"""
function Theta(
    m::CoxIngersollRossModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Theta(m)
    @assert size(X.X)[2] == 1  # require a single state
    @assert isa(X.params, NamedTuple)
    x_s = X(state_alias(m)[1])  # this should be a vector with size (1,)
    z_s = cir_z0(m) * exp.(x_s)
    (a, b2) = cir_lognormal_approximation(m,z_s,X.params)
    Θ_x = a .- log(cir_z0(m))
    #
    return Θ_x
end


"""
    H_T(
        m::CoxIngersollRossModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the transposed of the convection matrix H for simulation over the time period
[s, t].

There is no benefit in allowing H_T to be state-dependent. If H_T would need to be
state-dependent then it should be incorporated into Theta.
"""
function H_T(
    m::CoxIngersollRossModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_H(m)
    return zeros((1,1))
end


"""
    Sigma_T(
        m::CoxIngersollRossModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a matrix-valued function representing the volatility matrix function.
"""
function Sigma_T(
    m::CoxIngersollRossModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Sigma(m)
    @assert size(X.X)[2] == 1  # require a single state
    @assert isa(X.params, NamedTuple)
    x_s = X(state_alias(m)[1])
    z_s = cir_z0(m) * exp.(x_s)
    (a, b2) = cir_lognormal_approximation(m,z_s,X.params)
    Σ_x = sqrt.(b2 ./ (t-s))
    f(u) = reshape(Σ_x, (1,1))
    return f
end


"""
    diagonal_volatility(
        m::CoxIngersollRossModel,
        s::ModelTime,
        t::ModelTime,
        X::ModelState,
        )

Calculate the path-dependent volatilities for CoxIngersollRossModel.

`X` is supposed to hold a state matrix of size `(n, p)`. Here, `n` is
`length(state_alias(m))` and `p` is the number of paths.

The method returns a matrix of size `(n, p)`.
"""
function diagonal_volatility(
    m::CoxIngersollRossModel,
    s::ModelTime,
    t::ModelTime,
    X::ModelState,
    )
    @assert isa(X.params, NamedTuple)
    x_s = X(state_alias(m)[1])  # this is a vector of the x-variable
    z_s = cir_z0(m) * exp.(x_s)
    (a, b2) = cir_lognormal_approximation(m,z_s,X.params)
    Σ_x = sqrt.(b2 ./ (t-s))
    return reshape(Σ_x, (1,:))
end
