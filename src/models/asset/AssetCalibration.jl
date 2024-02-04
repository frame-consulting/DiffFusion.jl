

"""
    lognormal_asset_model(
        alias::String,
        dom_model::Union{GaussianHjmModel, Nothing},
        for_model::Union{GaussianHjmModel, Nothing},
        ch::Union{CorrelationHolder, Nothing},
        option_times::AbstractVector,
        asset_volatilities::AbstractVector,
        )

Calibrate an asset model to implied lognormal volatilities.
"""
function lognormal_asset_model(
    alias::String,
    dom_model::Union{GaussianHjmModel, Nothing},
    for_model::Union{GaussianHjmModel, Nothing},
    ch::Union{CorrelationHolder, Nothing},
    option_times::AbstractVector,
    asset_volatilities::AbstractVector,
    )
    #
    # check inputs first
    @assert length(option_times) > 0
    @assert option_times[1] > 0
    if length(option_times) > 1
        for (T0, T1) in zip(option_times[1:end-1], option_times[2:end])
            @assert T0 < T1
        end
    end
    @assert length(asset_volatilities) == length(option_times)
    function model(x::ModelValue, m::LognormalAssetModel, idx::Integer)
        @assert idx > 0
        @assert idx <= length(m.sigma_x.times)
        σ = exp(x)  #  make sure all inputs are positive
        sigma_x_ = hcat(
            m.sigma_x.values[:,1:idx-1],
            σ .* ones((1, length(m.sigma_x.times)-idx+1)),
        )
        sigma_x = backward_flat_volatility("", m.sigma_x.times, sigma_x_)
        return lognormal_asset_model(alias, sigma_x, ch, nothing)
    end
    x0 = log(asset_volatilities[1])
    σ0 = backward_flat_volatility("", option_times, zeros((1, length(option_times))))
    m0 = lognormal_asset_model(alias, σ0, ch, nothing)
    function obj_F(x::ModelValue, m::LognormalAssetModel, idx::Integer)
        m = model(x, m, idx)
        σ = model_implied_volatilties(m, dom_model, for_model, ch, option_times[idx:idx])[1]
        return σ - asset_volatilities[idx]
    end
    #
    min_max = (log(1.0e-4), log(2.0 * max(asset_volatilities...)))
    for idx in eachindex(option_times)
        f(x) = obj_F(x, m0, idx)
        x0 = find_zero(f, min_max, Roots.Brent(), xatol=1.0e-8)
        m0 = model(x0, m0, idx)
    end
    #
    m1 = model(x0, m0, length(option_times))
    fit = model_implied_volatilties(m1, dom_model, for_model, ch, option_times) - asset_volatilities
    return (model=m1, fit=fit)        
end
