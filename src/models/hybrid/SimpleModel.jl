
"""
    struct SimpleModel <: Model
        alias::String
        models::Tuple
        state_alias::Vector{String}
        factor_alias::Vector{String}
        model_dict::Dict{String,Int}
    end

A `SimpleModel` represents a collection of (coupled) state-independent
component models.

It is supposed to be used with a `simple_simulation()` method.
"""
struct SimpleModel{ModelsType<:Tuple} <: CompositeModel
    alias::String
    models::ModelsType
    state_alias::Vector{String}
    factor_alias::Vector{String}
    model_dict::Dict{String,Int}
end


"""
simple_model(alias::String, models::AbstractVector)

Create a SimpleModel.
"""
function simple_model(m_alias::String, models::AbstractVector)
    s_alias = vcat((state_alias(cm) for cm in models)...)
    f_alias = vcat((factor_alias(cm) for cm in models)...)
    model_dict = Dict{String,Int}()
    for (k,cm) in enumerate(models)
        model_dict[alias(cm)] = k
    end
    return SimpleModel(m_alias, Tuple(cm for cm in models), s_alias, f_alias, model_dict)
end


"""
    Theta(
        m::SimpleModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the deterministic drift component for simulation over the time period [s, t].
"""
function Theta(
    m::SimpleModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Theta(m)
    return vcat([Theta(cm,s,t,X) for cm in m.models]...)
end


"""
    H_T(
        m::SimpleModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the transposed of the convection matrix H for simulation over the time period
[s, t].
"""
function H_T(
    m::SimpleModel,
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
        m::SimpleModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a matrix-valued function representing the volatility matrix function.

The signature of the resulting function is (u::ModelTime). Here, u represents the
observation time.
"""
function Sigma_T(
    m::SimpleModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Sigma(m)
    for cm in m.models
        @assert state_alias(cm) == state_alias_Sigma(cm)  # deal with general case later...
        @assert factor_alias(cm) == factor_alias_Sigma(cm)
    end
    Sigma_T_s = ( Sigma_T(cm,s,t,X) for cm in m.models )
    M = length(state_alias_Sigma(m))
    N = length(factor_alias_Sigma(m))
    f = (u) -> begin
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
