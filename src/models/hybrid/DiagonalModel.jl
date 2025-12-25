

"""
    struct DiagonalModel <: CompositeModel
        alias::String
        models::Tuple
        state_alias::AbstractVector
        factor_alias::AbstractVector
        state_alias_Sigma::AbstractVector
        model_dict::Dict{String,Int}
    end

`DiagonalModel` represents a collection of (coupled) component models.
For the component models we assume that the models are either
state-independent models or diagonal models in the sense that the
correlation matrix is state-independent.

For state-independent models we avoid repeated Theta and Sigma calculation.

The model is used as a hybrid model for simulation and payoff evaluation.
"""
struct DiagonalModel <: CompositeModel
    alias::String
    models::Tuple
    state_alias::AbstractVector
    factor_alias::AbstractVector
    state_alias_Sigma::AbstractVector
    model_dict::Dict{String,Int}
end

"""
    diagonal_model(alias::String, models::AbstractVector)

Create a DiagonalModel.
"""
function diagonal_model(m_alias::String, models::AbstractVector)
    s_alias = vcat((state_alias(cm) for cm in models)...)
    f_alias = vcat((factor_alias(cm) for cm in models)...)
    s_alias_Sigma = vcat((state_alias_Sigma(cm) for cm in models)...)
    model_dict = Dict()
    for (k,cm) in enumerate(models)
        model_dict[alias(cm)] = k
    end
    return DiagonalModel(
        m_alias,
        Tuple(cm for cm in models),
        s_alias,
        f_alias,
        s_alias_Sigma,
        model_dict,
    )
end


"""
    state_alias_Sigma(m::DiagonalModel)

Return a list of state alias strings required for (Sigma(u)' Gamma Sigma(u)) calculation.
"""
state_alias_Sigma(m::DiagonalModel) = m.state_alias_Sigma


"""
    Theta(
        m::DiagonalModel,
        s::ModelTime,
        t::ModelTime,
        X::ModelState,
        )

Return the deterministic drift component for simulation over the time period [s, t].
"""
function Theta(
    m::DiagonalModel,
    s::ModelTime,
    t::ModelTime,
    X::ModelState,
    )
    @assert size(X.X)[2] == 1  # require a single state
    @assert isa(X.params, NamedTuple)
    return vcat([
        (!state_dependent_Theta(cm)) ? Θ : Theta(cm, s, t, ModelState(X.X, X.idx, P))
        for (cm, Θ, P) in zip(m.models, X.params.Θ, X.params.P)
        ]...)
end


"""
    H_T(
        m::DiagonalModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the transposed of the convection matrix H for simulation over the time period
[s, t].
"""
function H_T(
    m::DiagonalModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_H(m)
    I = Int[]
    J = Int[]
    V = zeros(0)
    idx = 0
    for cm in m.models
        @assert state_alias(cm) == state_alias_H(cm)  # deal with general case later...
        I_, J_, V_ = _coo_matrix(H_T(cm,s,t,X), idx, idx)
        I = vcat(I, I_)
        J = vcat(J, J_)
        V = vcat(V, V_)
        idx += length(state_alias(cm))
    end
    M = length(state_alias_H(m))
    N = length(state_alias(m))
    H_T_ = sparse(I, J, V, M, N)
    return H_T_
end


"""
    Sigma_T(
        m::DiagonalModel,
        s::ModelTime,
        t::ModelTime,
        X::ModelState,
        )

Return a matrix-valued function representing the volatility matrix function.

The signature of the resulting function is (u::ModelTime). Here, u represents the
observation time.
"""
function Sigma_T(
    m::DiagonalModel,
    s::ModelTime,
    t::ModelTime,
    X::ModelState,
    )
    @assert size(X.X)[2] == 1  # require a single state
    @assert isa(X.params, NamedTuple)
    Sigma_T_s = (
        (!state_dependent_Sigma(cm)) ? (Sigma_T(cm, s, t)) : (Sigma_T(cm, s, t, ModelState(X.X, X.idx, P)))
        for (cm, P) in zip(m.models, X.params.P)
    )
    M = length(state_alias_Sigma(m))
    N = length(factor_alias_Sigma(m))
    f(u) = begin
        I = Int[]
        J = Int[]
        V = zeros(0)
        idx_i = 0
        idx_j = 0
        for (cm, sigma) in zip(m.models, Sigma_T_s)
            I_, J_, V_ = _coo_matrix(sigma(u), idx_i, idx_j)
            I = vcat(I, I_)
            J = vcat(J, J_)
            V = vcat(V, V_)
            idx_i += length(state_alias_Sigma(cm))
            idx_j += length(factor_alias_Sigma(cm))
        end
        sigma_T = sparse(I, J, V, M, N)
        return sigma_T
    end
    return f
end


"""
    simulation_parameters(
        m::DiagonalModel,
        ch::Union{CorrelationHolder, Nothing},
        s::ModelTime,
        t::ModelTime,
        )

Pre-calculate parameters that are used in state-dependent Theta and Sigma calculation.
"""
function simulation_parameters(
    m::DiagonalModel,
    ch::Union{CorrelationHolder, Nothing},
    s::ModelTime,
    t::ModelTime,
    )
    #
    Θ = [
        (!state_dependent_Theta(cm)) ? (Theta(cm, s, t)) : (nothing)
        for cm in m.models
    ]
    Σ = [
        (!state_dependent_Sigma(cm)) ? (volatility_and_correlation(cm, ch, s, t)[1]) : (nothing)  # only volatility
        for cm in m.models
    ]
    P = [
        (state_dependent_Theta(cm) || state_dependent_Sigma(cm)) ?
        (simulation_parameters(cm, ch, s, t)) : (nothing)
        for cm in m.models
    ]
    return (Θ=Θ, Σ=Σ, P=P)
end


"""
    diagonal_volatility(
        m::DiagonalModel,
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
    m::DiagonalModel,
    s::ModelTime,
    t::ModelTime,
    X::ModelState,
    )
    @assert isa(X.params, NamedTuple)
    p = size(X.X)[2]
    V = [
        (!state_dependent_Sigma(cm)) ? (hcat([Σ for k in 1:p]...) ) :
        diagonal_volatility(cm, s, t, ModelState(X.X, X.idx, P))
        for (cm, Σ, P) in zip(m.models, X.params.Σ, X.params.P)
    ]
    return vcat(V...)
end
