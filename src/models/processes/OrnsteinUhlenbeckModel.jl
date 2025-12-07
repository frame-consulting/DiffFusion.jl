
"""
An Ornstein-Uhlenbeck model with constant mean reversion
and piece-wise flat volatility.
"""
struct OrnsteinUhlenbeckModel <: ComponentModel
    alias::String
    chi::ParameterTermstructure
    sigma_x::BackwardFlatVolatility
    state_alias::AbstractVector
    factor_alias::AbstractVector
end


"""
    ornstein_uhlenbeck_model(
        alias::String,
        chi::ParameterTermstructure,
        sigma_x::BackwardFlatVolatility,
        )

Create an Ornstein-Uhlenbeck model.
"""
function ornstein_uhlenbeck_model(
    alias::String,
    chi::ParameterTermstructure,
    sigma_x::BackwardFlatVolatility,
    )
    # check inputs first
    @assert length(chi()) == 1  # scalar and constant mean reversion
    @assert length(sigma_x(0.0)) == 1  # scalar volatility
    state_alias = [ alias * "_x" ]
    factor_alias = [ alias * "_x" ]
    return OrnsteinUhlenbeckModel(alias, chi, sigma_x, state_alias, factor_alias)
end


# Model interface

"""
Return a list of times representing the (joint) grid points of piece-wise
constant model parameters.
"""
parameter_grid(m::OrnsteinUhlenbeckModel) = m.sigma_x.times

"""
Return whether Theta requires a state vector input X.
"""
state_dependent_Theta(m::OrnsteinUhlenbeckModel) = false

"""
Return a list of state alias strings required for (H * X) calculation.
"""
state_alias_H(m::OrnsteinUhlenbeckModel) = state_alias(m)

"""
Return whether H requires a state vector input X.
"""
state_dependent_H(m::OrnsteinUhlenbeckModel) = false

"""
Return a list of factor alias strings required for (Sigma(u)^T Gamma Sigma(u)) calculation.
"""
factor_alias_Sigma(m::OrnsteinUhlenbeckModel) = factor_alias(m)

"""
Return whether Sigma requires a state vector input X.
"""
state_dependent_Sigma(m::OrnsteinUhlenbeckModel) = false


"""
    Theta(
        m::OrnsteinUhlenbeckModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the deterministic drift component for simulation over the time period [s, t].
"""
function Theta(
    m::OrnsteinUhlenbeckModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Theta(m)
    return zeros(1)
end


"""
    H_T(
        m::OrnsteinUhlenbeckModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the transposed of the convection matrix H for simulation over the time period
[s, t].
"""
function H_T(
    m::OrnsteinUhlenbeckModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_H(m)
    return reshape(H_hjm(m.chi(), s, t), 1, 1)
end


"""
    Sigma_T(
        m::OrnsteinUhlenbeckModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a matrix-valued function representing the volatility matrix function.

The signature of the resulting function is (u::ModelTime). Here, u represents the
observation time.
"""
function Sigma_T(
    m::OrnsteinUhlenbeckModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Sigma(m)
    f(u) = reshape(H_hjm(m.chi(), u, t) .* m.sigma_x(u), 1, 1)
    return f
end


"""
    simulation_parameters(
        m::OrnsteinUhlenbeckModel,
        ch::Union{CorrelationHolder, Nothing},
        s::ModelTime,
        t::ModelTime,
        )

Pre-calculate parameters that are used in state-dependent Theta and Sigma calculation.

For OrnsteinUhlenbeckModel there are no valuations that should be cached.
"""
function simulation_parameters(
    m::OrnsteinUhlenbeckModel,
    ch::Union{CorrelationHolder, Nothing},
    s::ModelTime,
    t::ModelTime,
    )
    #
    return nothing
end
