
"""
    abstract type AssetModel <: ComponentModel end

An `AssetModel` aims at modelling spot prices of tradeable assets like
FX, shares and indices.

We implement several additional functions to handle quanto adjustments.
"""
abstract type AssetModel <: ComponentModel end

"""
    abstract type AssetVolatility end

A functor calculating the state-independent volatility function sigma(u) for the interval (s,t).
"""
abstract type AssetVolatility end


"""
    asset_volatility(
        m::AssetModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return an AssetVolatility functor.
"""
function asset_volatility(
    m::AssetModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    error("AssetModel needs to implement asset_volatility method.")
end

"""
    correlation_holder(m::AssetModel)

Return the correlation holder term structure.
"""
function correlation_holder(m::AssetModel)
    return m.correlation_holder
end

"""
    abstract type QuantoDrift end

A functor calculating the state-independent quanto drift adjustment.
"""
abstract type QuantoDrift end

"""
A trivial quanto adjustment.
"""
struct ZeroQuantoDrift <: QuantoDrift
    d::Int
end

"""
Evaluate `ZeroQuantoDrift` at `t`.
"""
(qd::ZeroQuantoDrift)(t::ModelTime) = zeros(qd.d)

"""
    quanto_drift(
        dom_factor_alias::AbstractVector,
        quanto_model::Nothing,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a zero quanto adjustment function alpha(u).
"""
function quanto_drift(
    dom_factor_alias::AbstractVector,
    quanto_model::Nothing,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    #
    return ZeroQuantoDrift(length(dom_factor_alias))
end

"""
Quanto adjustment functor for `AssetModel`.
"""
struct AssetModelQuantoDrift{T1<:ModelValue, T2<:AssetVolatility} <: QuantoDrift
    Gamma::Vector{T1}
    vol::T2
end

"""
Evaluate `AssetModelQuantoDrift` at `t`.
"""
(qd::AssetModelQuantoDrift)(t::ModelTime) = qd.Gamma .* qd.vol(t)

"""
    quanto_drift(
        dom_factor_alias::AbstractVector,
        quanto_model::AssetModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a function alpha(u) that allows to calculate the quanto adjustment
on the time interval (s,t).
"""
function quanto_drift(
    dom_factor_alias::AbstractVector,
    quanto_model::AssetModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    ch = correlation_holder(quanto_model)
    quanto_factor_alias = factor_alias(quanto_model)[begin]  # This is an assumption
    # ch() returns an (N,1) matrix, but we want to return an (N,) vector
    Gamma = vec(ch(dom_factor_alias, quanto_factor_alias))
    vol = asset_volatility(quanto_model, s, t, X)
    return AssetModelQuantoDrift(Gamma, vol)
end
