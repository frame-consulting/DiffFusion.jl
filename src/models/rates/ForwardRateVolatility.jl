
"""
    forward_rate_variance(
        m::GaussianHjmModel,
        t::ModelTime,
        T::ModelTime,
        T0::ModelTime,
        T1::ModelTime,
        )

Calculate the lognormal variance for a compounding factor of a forward-looking
or backward-looking forward rate.

Time `t` is the observation time, `T` is the rate fixing time or option exercise
time, `T0` is the rate period start time, and `T1` is the rate period end time.

If `t ≤ T0` then we calculate the variance for a forward-looking rate. If
`t = T1` then we calculate the variance for a backward-looking rate.
"""
function forward_rate_variance(
    m::GaussianHjmModel,
    t::ModelTime,
    T::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    )
    #
    @assert (T ≤ T0) || (T == T1)
    if t ≥ T
        return 0.0  # rate is fixed
    end
    #
    T_min = min(T, T0)
    t_min = min(t, T_min)
    #
    y_t = func_y(m, t_min)
    y_T = func_y(m, T_min)
    H = H_hjm(m, t_min, T_min)
    y = y_T .- Diagonal(H) * y_t * Diagonal(H)  # Cov[x_T | x_t]
    #
    G1 = G_hjm(m, min(T, T0), T1)
    G0 = G_hjm(m, min(T, T0), T0)
    G = G1 .- G0
    ν² = G' * y * G
    #
    if T ≤ T0
        return ν²  # forward looking rate
    end
    #
    cov = covariance(m, m.correlation_holder, max(t, T0), T1, nothing)[end,end]  # z variable variance
    return ν² .+ cov
end

"""
    forward_rate_variance(
        m::GaussianHjmModel,
        alias::String,
        t::ModelTime,
        T::ModelTime,
        T0::ModelTime,
        T1::ModelTime,
        )

Calculate the lognormal variance for a compounding factor of a forward-looking
or backward-looking forward rate.

This function implements the Model interface function.
"""
function forward_rate_variance(
    m::GaussianHjmModel,
    alias::String,
    t::ModelTime,
    T::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    )
    #
    @assert alias == m.alias
    return forward_rate_variance(m, t, T, T0, T1)
end
