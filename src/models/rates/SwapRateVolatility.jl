
"""
    zero_bond(
        yts::YieldTermstructure,
        m::GaussianHjmModel,
        t::ModelTime,
        T::ModelTime,
        SX::ModelState,
        )

Zero bond price reconstruction.

Returns a vector of length p where p is the number of paths in SX.
"""
function zero_bond(
    yts::YieldTermstructure,
    m::GaussianHjmModel,
    t::ModelTime,
    T::ModelTime,
    SX::ModelState,
    )
    #
    df1 = discount(yts, t)
    df2 = discount(yts, T)
    s = log_zero_bond(m, alias(m), t, T, SX)
    zb = (df2/df1) * exp.(-s)
    return zb
end


"""
    swap_rate_gradient(
        yts::YieldTermstructure,
        m::GaussianHjmModel,
        t::ModelTime,
        swap_times::AbstractVector,
        yf_weights::AbstractVector,
        SX::ModelState,
        )

The gradient dS/dx in a Gaussian HJM model.

Returns a matrix of size (p, d). Here, p is the number of paths
in SX and d is the number of factors of the GHJM model, i.e.,
d = length(factor_alias(m)).

Observation time is `t`. The swap rate is specified by `swap_times`
and `yf_weights`. `swap_times[begin]` is the start time of the first
(floating rate) coupon period. `swap_times[k]` for `k>begin`
represent the pay times of the fixed leg coupons. `yf_weights` are
the year fractions of the fixed leg coupons.

The swap rate is constructed assuming single-curve setting without
tenor basis. `yts` is the initial (discounting) yield curve.

The swap rate gradient depends on the simulated model state at `t`.
The model state is encoded in `SX`.
"""
function swap_rate_gradient(
    yts::YieldTermstructure,
    m::GaussianHjmModel,
    t::ModelTime,
    swap_times::AbstractVector,
    yf_weights::AbstractVector,
    SX::ModelState,
    )
    #
    @assert length(swap_times) > 1
    @assert length(swap_times) == length(yf_weights) + 1
    @assert t <= swap_times[1]
    #
    P = hcat([ zero_bond(yts, m, t, T, SX) for T in swap_times ]...)
    G = hcat([ G_hjm(m, t, T) for T in swap_times ]...)
    w = yf_weights # abbreviation
    An = sum(( w[i] * P[:,i+1] for i in eachindex(w) ))
    S = (P[:,1] - P[:,end]) ./ An
    # see AP10, sec. 12.1.6.2, p. 506; note the typo in the sign!
    q = -(P[:,1] * G[:,1]' - P[:,end] * G[:,end]') ./ An
    q = q + S .* sum(( w[i] * P[:,i+1] * G[:,i+1]' for i in eachindex(w) )) ./ An
    return q
end

"""
    swap_rate_instantaneous_covariance(
        yts::YieldTermstructure,
        m::GaussianHjmModel,
        t::ModelTime,
        swap_times_1::AbstractVector,
        yf_weights_1::AbstractVector,
        swap_times_2::AbstractVector,
        yf_weights_2::AbstractVector,
        SX::ModelState,
        )

Calculate the instantaneous covariance of two swap rates.

See method `swap_rate_gradient` for details on the
input parameters.
"""
function swap_rate_instantaneous_covariance(
    yts::YieldTermstructure,
    m::GaussianHjmModel,
    t::ModelTime,
    swap_times_1::AbstractVector,
    yf_weights_1::AbstractVector,
    swap_times_2::AbstractVector,
    yf_weights_2::AbstractVector,
    SX::ModelState,
    )
    q1 = swap_rate_gradient(yts, m, t, swap_times_1, yf_weights_1, SX)
    q2 = swap_rate_gradient(yts, m, t, swap_times_2, yf_weights_2, SX)
    σT = m.sigma_T(t)
    q1_σT = q1 * σT   # size (p, d)
    q2_σT = q2 * σT   # size (p, d)
    cov = sum(q1_σT .* q2_σT, dims=2)[:,1]
    return cov
end



"""
    swap_rate_volatility²(
        yts::YieldTermstructure,
        m::GaussianHjmModel,
        t::ModelTime,
        swap_times::AbstractVector,
        yf_weights::AbstractVector,
        SX::ModelState,
        )

Calculate the square of swap rate volatility (or instantaneous variance).

See method `swap_rate_gradient` for details on the input parameters.
"""
function swap_rate_volatility²(
    yts::YieldTermstructure,
    m::GaussianHjmModel,
    t::ModelTime,
    swap_times::AbstractVector,
    yf_weights::AbstractVector,
    SX::ModelState,
    )
    q = swap_rate_gradient(yts, m, t, swap_times, yf_weights, SX)
    σT = m.sigma_T(t)
    q_σT = q * σT   # size (p, d)
    σ² = sum(q_σT.^2, dims=2)[:,1]
    return σ²
end


"""
    swap_rate_covariance(
        yts::YieldTermstructure,
        m::GaussianHjmModel,
        t::ModelTime,
        T::ModelTime,
        swap_times_1::AbstractVector,
        yf_weights_1::AbstractVector,
        swap_times_2::AbstractVector,
        yf_weights_2::AbstractVector,
        SX::ModelState,
        )

Calculate the covariance of two swap rates over the time intervall (t,T).

See method `swap_rate_gradient` for details on the input parameters.
"""
function swap_rate_covariance(
    yts::YieldTermstructure,
    m::GaussianHjmModel,
    t::ModelTime,
    T::ModelTime,
    swap_times_1::AbstractVector,
    yf_weights_1::AbstractVector,
    swap_times_2::AbstractVector,
    yf_weights_2::AbstractVector,
    SX::ModelState,
    )
    #
    cov(u) = swap_rate_instantaneous_covariance(yts, m, u, swap_times_1, yf_weights_1, swap_times_2, yf_weights_2, SX)
    γ = _vector_integral(cov, t, T, m.sigma_T.sigma_f.times)
    return γ
end


"""
    swap_rate_variance(
        yts::YieldTermstructure,
        m::GaussianHjmModel,
        t::ModelTime,
        T::ModelTime,
        swap_times::AbstractVector,
        yf_weights::AbstractVector,
        SX::ModelState,
        )

Calculate the normal model variance of a swap rate via Gaussian swap rate approximation.

Observation time is `t`, Option expiry time is `T`.

See method `swap_rate_gradient` for details on further input parameters.
"""
function swap_rate_variance(
    yts::YieldTermstructure,
    m::GaussianHjmModel,
    t::ModelTime,
    T::ModelTime,
    swap_times::AbstractVector,
    yf_weights::AbstractVector,
    SX::ModelState,
    )
    #
    σ²(u) = swap_rate_volatility²(yts, m, u, swap_times, yf_weights, SX)
    ν² = _vector_integral(σ², t, T, m.sigma_T.sigma_f.times)
    return ν²
end


"""
    swap_rate_variance(
        m::GaussianHjmModel,
        alias::String,
        yts::YieldTermstructure,
        t::ModelTime,
        T::ModelTime,
        swap_times::AbstractVector,
        yf_weights::AbstractVector,
        X::ModelState,
        )

Calculate the normal model variance of a swap rate via Gaussian swap rate approximation.

This function is implements the Model interface function.

See method `swap_rate_gradient` for details on further input parameters.
"""
function swap_rate_variance(
    m::GaussianHjmModel,
    alias::String,
    yts::YieldTermstructure,
    t::ModelTime,
    T::ModelTime,
    swap_times::AbstractVector,
    yf_weights::AbstractVector,
    X::ModelState,
    )
    #
    @assert alias == m.alias
    return swap_rate_variance(yts, m, t, T, swap_times, yf_weights, X)
end


"""
    swap_rate_correlation(
        yts::YieldTermstructure,
        m::GaussianHjmModel,
        t::ModelTime,
        T::ModelTime,
        swap_times_1::AbstractVector,
        yf_weights_1::AbstractVector,
        swap_times_2::AbstractVector,
        yf_weights_2::AbstractVector,
        SX::ModelState,
        )

Calculate the correlation of two swap rates via Gaussian swap rate approximation
over the time intervall (t,T).

See method `swap_rate_gradient` for details on further input parameters.
"""
function swap_rate_correlation(
    yts::YieldTermstructure,
    m::GaussianHjmModel,
    t::ModelTime,
    T::ModelTime,
    swap_times_1::AbstractVector,
    yf_weights_1::AbstractVector,
    swap_times_2::AbstractVector,
    yf_weights_2::AbstractVector,
    SX::ModelState,
    )
    #
    cov = swap_rate_covariance(yts, m, t, T, swap_times_1, yf_weights_1, swap_times_2, yf_weights_2, SX)
    ν1² = swap_rate_variance(yts, m, t, T, swap_times_1, yf_weights_1, SX)
    ν2² = swap_rate_variance(yts, m, t, T, swap_times_2, yf_weights_2, SX)
    return cov ./ sqrt.(ν1² .* ν2²)
end


"""
    model_implied_volatilties(
        yts::YieldTermstructure,
        m::GaussianHjmModel,
        option_times::AbstractVector,
        swap_times::AbstractMatrix,
        swap_weights::AbstractMatrix,
        SX::Union{ModelState, Nothing} = nothing
        )

Calculate model-implied swap rate volatilities in Gaussian HJM model.

`option_times` are the option expiry times.

`swap_times` is a matrix of vectors. Each element represents swap times as
specified in `swap_rate_gradient`.

`swap_weights` is a matrix of vectors. Each element represents year fraction weights
as specified in `swap_rate_gradient`.

See method `swap_rate_gradient` for details on further input parameters.
"""
function model_implied_volatilties(
    yts::YieldTermstructure,
    m::GaussianHjmModel,
    option_times::AbstractVector,
    swap_times::AbstractMatrix,
    swap_weights::AbstractMatrix,
    SX::Union{ModelState, Nothing} = nothing
    )
    #
    @assert length(option_times) == size(swap_times)[1]
    @assert size(swap_times) == size(swap_weights)
    #
    if isnothing(SX)
        X = zeros( (length(state_alias(m)), 1) )
        SX = model_state(X, m)
    end
    @assert size(SX.X)[2] == 1  # we calculate vols only for a single (trivial) state
    #
    ν² = [
        swap_rate_variance(yts, m, 0.0, option_times[i], swap_times[i,j], swap_weights[i,j], SX)[1]
        for i in axes(swap_times, 1), j in axes(swap_times, 2)
    ]
    return sqrt.( ν² ./ option_times )
end


"""
    model_implied_volatilties(
        yts::YieldTermstructure,
        m::GaussianHjmModel,
        option_times::AbstractVector,
        swap_times::AbstractVector,
        swap_weights::AbstractVector,
        SX::Union{ModelState, Nothing} = nothing
        )

Calculate model-implied swap rate volatilities in Gaussian HJM model.

`option_times` are the option expiry times.

`swap_times` is a vector of vectors. Each element represents time offsets that
are added to `option_times` in order to form `swap_times` as specified in
`swap_rate_gradient`.

`swap_weights` is a vector of vectors. Each element represents year fraction weights
as specified in `swap_rate_gradient`. `swap_weights` are assumed equal per expiry
time.

See method `swap_rate_gradient` for details on further input parameters.
"""
function model_implied_volatilties(
    yts::YieldTermstructure,
    m::GaussianHjmModel,
    option_times::AbstractVector,
    swap_times::AbstractVector,
    swap_weights::AbstractVector,
    SX::Union{ModelState, Nothing} = nothing
    )
    #
    @assert length(swap_times) == length(swap_weights)
    swap_times_matrix = [
        option_times[i] .+ swap_times[j]
        for i in eachindex(option_times), j in eachindex(swap_times)
    ]
    swap_weights_matrix = [
        swap_weights[j]
        for i in eachindex(option_times), j in eachindex(swap_times)
    ]
    return model_implied_volatilties(yts, m, option_times, swap_times_matrix, swap_weights_matrix, SX)
end


"""
    model_implied_volatilties(
        yts::YieldTermstructure,
        m::GaussianHjmModel,
        option_times::AbstractVector,
        swap_maturities::AbstractVector,
        SX::Union{ModelState, Nothing} = nothing
        )

Calculate model-implied swap rate volatilities in Gaussian HJM model.

`option_times` are the option expiry times.

`swap_maturities` is a list of swap tenors. Swap times and year fraction weights are
calculated from `swap_maturities` assuming an annual schedule.

See method `swap_rate_gradient` for details on further input parameters.
"""
function model_implied_volatilties(
    yts::YieldTermstructure,
    m::GaussianHjmModel,
    option_times::AbstractVector,
    swap_maturities::AbstractVector,
    SX::Union{ModelState, Nothing} = nothing
    )
    #
    swap_times = [
        0:maturity for maturity in swap_maturities
    ]
    swap_weights = [
        times[2:end] - times[1:end-1] for times in swap_times
    ]
    return model_implied_volatilties(yts, m, option_times, swap_times, swap_weights, SX)
end

