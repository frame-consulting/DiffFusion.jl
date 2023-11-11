


"""
    gaussian_hjm_model(
        alias::String,
        ch::Union{CorrelationHolder, Nothing},
        option_times::AbstractVector,
        swap_maturities::AbstractVector,
        swap_rate_volatilities::AbstractMatrix,
        yts::YieldTermstructure;
        max_iter::Integer = 5,
        volatility_regularisation::ModelValue = 0.0,
        )

Calibrate a model with flat volatilities and mean reversion
to strips of co-initial normal volatilities.
"""
function gaussian_hjm_model(
    alias::String,
    ch::Union{CorrelationHolder, Nothing},
    option_times::AbstractVector,
    swap_maturities::AbstractVector,
    swap_rate_volatilities::AbstractMatrix,
    yts::YieldTermstructure;
    max_iter::Integer = 5,
    volatility_regularisation::ModelValue = 0.0,
    )
    #
    # check inputs first
    @assert length(option_times) > 0
    for T in option_times
        @assert T > 0.0
    end
    @assert length(swap_maturities) > 0
    for j in 2:length(swap_maturities)
        @assert swap_maturities[j] > swap_maturities[j-1]
    end
    @assert size(swap_rate_volatilities) == (length(option_times), length(swap_maturities))
    #
    @assert volatility_regularisation ≥ 0.0
    @assert volatility_regularisation ≤ 1.0
    #
    delta = flat_parameter(swap_maturities)
    d = length(swap_maturities)
    function model(x::AbstractVector)
        @assert length(x) == 2 * d
        exp_x = exp.(x)  #  make sure all inputs are positive
        d_chi = [ sum(exp_x[2:k]) for k in 2:d ]
        chi_ = vcat([exp_x[1]], exp_x[1] .+ d_chi)   #  ensure monotonicity
        chi = flat_parameter(chi_)
        sigma_f = backward_flat_volatility("", [0.0], reshape(exp_x[d+1:end], (:,1)) )
        return gaussian_hjm_model(alias, delta, chi, sigma_f, ch, nothing)
    end
    #
    x0 = log.(vcat(
        [ 0.01 ],
        0.1* ones(d-1),
        mean(swap_rate_volatilities, dims=1)[1,:]
    ))
    m0 = model(x0)
    X = zeros( (length(state_alias(m0)), 1) )
    SX = model_state(X, m0)
    function obj_F(x::AbstractVector)
        m = model(x)
        σ = model_implied_volatilties(yts, m, option_times, swap_maturities, SX)
        obj = vec(σ - swap_rate_volatilities)
        if volatility_regularisation > 0.0
            model_vol = m.sigma_T.sigma_f.values[:,1]
            obj_vol = model_vol[begin+1:end] - model_vol[begin:end-1]
            obj = vcat(
                (1.0 - volatility_regularisation) * obj,
                volatility_regularisation * obj_vol,
            )
        end
        return obj
    end
    #
    obj_model(p, x) = obj_F(x)
    y0 = obj_F(x0)
    res = LsqFit.curve_fit(
        obj_model,
        zeros(length(y0)),
        zeros(length(y0)),
        x0,
        maxIter  = max_iter,
        autodiff = :forwarddiff)
    #
    m1 = model(res.param)
    fit = model_implied_volatilties(yts, m1, option_times, swap_maturities, SX) - swap_rate_volatilities
    return (model=m1, fit=fit)
end


"""
    gaussian_hjm_model(
        alias::String,
        delta::ParameterTermstructure,
        chi::ParameterTermstructure,
        ch::Union{CorrelationHolder, Nothing},
        option_times::AbstractVector,
        swap_maturities::AbstractVector,
        swap_rate_volatilities::AbstractMatrix,
        yts::YieldTermstructure;
        max_iter::Integer = 5,
        volatility_regularisation::ModelValue = 0.0,
        )


Calibrate a model with piece-wise constant volatilities to strips of
co-initial normal volatilities.

Mean reversion (and correlations) are exogeneously specified.
"""
function gaussian_hjm_model(
    alias::String,
    delta::ParameterTermstructure,
    chi::ParameterTermstructure,
    ch::Union{CorrelationHolder, Nothing},
    option_times::AbstractVector,
    swap_maturities::AbstractVector,
    swap_rate_volatilities::AbstractMatrix,
    yts::YieldTermstructure;
    max_iter::Integer = 5,
    volatility_regularisation::ModelValue = 0.0,
    )
    #
    # check inputs first
    @assert length(option_times) > 0
    for T in option_times
        @assert T > 0.0
    end
    @assert length(delta()) == length(chi())
    @assert length(delta()) <= length(swap_maturities)
    @assert length(swap_maturities) > 0
    for j in 2:length(swap_maturities)
        @assert swap_maturities[j] > swap_maturities[j-1]
    end
    @assert size(swap_rate_volatilities) == (length(option_times), length(swap_maturities))
    #
    @assert volatility_regularisation ≥ 0.0
    @assert volatility_regularisation ≤ 1.0
    #
    d = length(delta())
    function model(x::AbstractVector, m::GaussianHjmModel, idx::Integer)
        @assert length(x) == d
        @assert idx > 0
        @assert idx <= length(m.sigma_T.sigma_f.times)
        σ = exp.(x)  #  make sure all inputs are positive
        # TODO: setup model only to idx-time
        sigma_f_ = hcat(
            m.sigma_T.sigma_f.values[:,1:idx-1],
            σ .* ones((d, length(m.sigma_T.sigma_f.times)-idx+1))
        )
        sigma_f = backward_flat_volatility("", m.sigma_T.sigma_f.times, sigma_f_)
        # TODO: use low-level incremental model construction
        return gaussian_hjm_model(alias, delta, chi, sigma_f, ch, nothing)
    end
    #
    x0 = log.(mean(swap_rate_volatilities) * ones(d))
    σ0 = backward_flat_volatility("", option_times, zeros((d, length(option_times))))
    m0 = gaussian_hjm_model(alias, delta, chi, σ0, ch, nothing)
    X = zeros( (length(state_alias(m0)), 1) )
    SX = model_state(X, m0)
    function obj_F(x::AbstractVector, m::GaussianHjmModel, idx::Integer)
        m = model(x, m, idx)
        σ = model_implied_volatilties(yts, m, option_times[idx:idx], swap_maturities, SX)
        obj = vec(σ - swap_rate_volatilities[idx:idx,:])
        if volatility_regularisation > 0.0
            model_vol = m.sigma_T.sigma_f.values[:,idx]
            obj_vol = model_vol[begin+1:end] - model_vol[begin:end-1]
            obj = vcat(
                (1.0 - volatility_regularisation) * obj,
                volatility_regularisation * obj_vol,
            )
        end
        return obj
    end
    #
    for idx in eachindex(option_times)
        obj_model(p, x) = obj_F(x, m0, idx)
        y0 = obj_F(x0, m0, idx)
        res = LsqFit.curve_fit(
            obj_model,
            zeros(length(y0)),
            zeros(length(y0)),
            x0,
            maxIter  = max_iter,
            autodiff = :forwarddiff)
        x0 = res.param
        m0 = model(x0, m0, idx)
    end
    #
    m1 = model(x0, m0, length(option_times))
    fit = model_implied_volatilties(yts, m1, option_times, swap_maturities, SX) - swap_rate_volatilities
    return (model=m1, fit=fit)
end
