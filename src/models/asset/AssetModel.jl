
"""
    abstract type AssetModel <: ComponentModel end

An `AssetModel` aims at modelling spot prices of tradeable assets like
FX, shares and indices.

We implement several additional functions to handle quanto adjustments.
"""
abstract type AssetModel <: ComponentModel end

"""
    asset_volatility(
        m::AssetModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a state-independent volatility function sigma(u) for the interval (s,t).
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
    alpha(u) = zeros(length(dom_factor_alias))
    return alpha
end


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
    quanto_factor_alias = factor_alias(quanto_model)[1]  # This is an assumption
    # ch() returns an (N,1) matrix, but we want to return an (N,) vector
    Gamma = vec(ch(dom_factor_alias, quanto_factor_alias))
    vol = asset_volatility(quanto_model,s,t,X)
    alpha(u) = Gamma * vol(u)
    return alpha
end
