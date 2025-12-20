
"""
    asset_variance(
        ast_model::LognormalAssetModel,
        dom_model::Union{GaussianHjmModel, Nothing},
        for_model::Union{GaussianHjmModel, Nothing},
        ch::CorrelationHolder,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Calculate lognormal variance in hybrid asset model.

The method is defined for a `LognormalAssetModel`. It should also work
for other asset models. But then we need to calculate a vector and this
requires more testing.
"""
function asset_variance(
    ast_model::Union{LognormalAssetModel, Nothing},
    dom_model::Union{GaussianHjmModel, Nothing},
    for_model::Union{GaussianHjmModel, Nothing},
    ch::CorrelationHolder,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    models_ = Model[ ]
    e = ones(0)
    if !isnothing(ast_model)
        models_ = Model[ ast_model ]
        e = ones(1)
    end
    if !isnothing(dom_model)
        models_ = vcat(models_, dom_model)
        n = length(state_alias_Sigma(dom_model))
        e = vcat(e, zeros(n-1), ones(1))
    end
    if !isnothing(for_model)
        models_ = vcat(models_, for_model)
        n = length(state_alias_Sigma(for_model))
        e = vcat(e, zeros(n-1), -1.0*ones(1))
    end
    model = simple_model("", models_)
    cov = covariance(model, ch, s, t, X)
    @assert(size(cov) == (length(e), length(e)))
    ν² = e' * cov * e
    return ν²
end
 

"""
    model_implied_volatilties(
        ast_model::LognormalAssetModel,
        dom_model::Union{GaussianHjmModel, Nothing},
        for_model::Union{GaussianHjmModel, Nothing},
        ch::CorrelationHolder,
        option_times::AbstractVector,
        )

Calculate model-implied volatilities in hybrid asset model.
"""
function model_implied_volatilties(
    ast_model::LognormalAssetModel,
    dom_model::Union{GaussianHjmModel, Nothing},
    for_model::Union{GaussianHjmModel, Nothing},
    ch::CorrelationHolder,
    option_times::AbstractVector,
    )
    #
    ν² = [
        asset_variance(ast_model, dom_model, for_model, ch, 0.0, T)
        for T in option_times
    ]
    return sqrt.( ν² ./ option_times )
end
