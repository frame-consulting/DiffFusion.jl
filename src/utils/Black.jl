
"""
    _d_1(strike, forward, nu)

Calculate the Black formula d_1 term.

We implement this once in order to fine-tune corner cases later.
"""
_d_1(strike, forward, nu) = log.(forward ./ strike) ./ nu .+ nu / 2.0


"""
    black_price(strike, forward, nu, call_put)

Calculate Vanilla option price V in Black model.

Argument `strike` (``K``) represents the option strike, `forward` (``F``) is the
forward price of the underlying ``S``, i.e. ``F = E[S(T)]`` in the respective
pricing measure.

Argument nu represents the standard deviation of the forward price. For
annualised lognormal volatility σ, we have ``ν = σ √T``. Finally, `call_put`
is the call (+1) or put (-1) option flag.

We allow broadcasting for arguments.
"""
function black_price(strike, forward, nu, call_put)
    intrinsic_value = max.(call_put * (forward .- strike), 0.0)
    d1 = _d_1(strike, forward, nu)
    d2 = d1 .- nu
    option_value = call_put * (
        forward .* cdf.(Normal(), call_put .* d1) .-
        strike  .* cdf.(Normal(), call_put .* d2)
        )
    return (nu .> 0.0) .* option_value .+ (nu .<= 0.0) .* intrinsic_value
end

"""
    black_price(strike, forward, σ, T, call_put)

Calculate Vanilla option price ``V`` in Black model with volatility parameter.
"""
black_price(strike, forward, σ, T, call_put) = black_price(strike, forward, σ * sqrt(T), call_put)


"""
    black_delta(strike, forward, nu, call_put)

Calculate Vanilla option Delta in Black model.
"""
function black_delta(strike, forward, nu, call_put)
    intrinsic_value = call_put * (forward .- strike) .> 0.0
    d1 = _d_1(strike, forward, nu)
    option_value = call_put .* cdf.(Normal(), call_put .* d1)
    return (nu .> 0.0) .* option_value + (nu .<= 0.0) .* intrinsic_value
end

"""
    black_delta(strike, forward, σ, T, call_put)

Calculate Vanilla option Delta in Black model with volatility parameter.
"""
black_delta(strike, forward, σ, T, call_put) = black_delta(strike, forward, σ * sqrt(T), call_put)


"""
    black_gamma(strike, forward, nu)

Calculate Vanilla option Gamma in Black model.
"""
function black_gamma(strike, forward, nu)
    d1 = _d_1(strike, forward, nu)
    return (nu .> 0.0) .* pdf.(Normal(), d1) ./ forward ./ max.(nu, 1.0e-14)
end

"""
    black_gamma(strike, forward, σ, T)

Calculate Vanilla option Gamma in Black model with volatility parameter.
"""
black_gamma(strike, forward, σ, T) = black_gamma(strike, forward, σ * sqrt(T))


"""
    black_theta(strike, forward, σ, T)

Calculate Vanilla option Theta in Black model.
"""
function black_theta(strike, forward, σ, T)
    return -0.5 .* (σ .* forward).^2 .* black_gamma(strike, forward, σ, T)
end


"""
    black_vega(strike, forward, nu)

Calculate Vanilla option Vega in Black model.

Here, Vega is calculated as ``dV / d ν``.
"""
function black_vega(strike, forward, nu)
    d1 = _d_1(strike, forward, max.(nu, 1.0e-14))
    return forward .* pdf.(Normal(), d1)
end

"""
    black_vega(strike, forward, σ, T)

Calculate Vanilla option Vega in Black model with volatility parameter..

Here, Vega is calculated as ``dV / dσ``.
"""
black_vega(strike, forward, σ, T) = black_vega(strike, forward, σ * sqrt(T)) * sqrt(T)


"""
    black_implied_stdev(price, strike, forward, call_put, min_max = (0.01, 3.00))

Calculate the implied log-normal standard deviation ν from a Black model price.
"""
function black_implied_stdev(price, strike, forward, call_put, min_max = (0.01, 3.00))
    f(nu) = black_price(strike, forward, nu, call_put) - price
    nu = find_zero(f, min_max, Roots.Brent(), xatol=1.0e-8)
    return nu
end

"""
    black_implied_volatility(price, strike, forward, T, call_put, min_max = (0.01, 1.00))

Calculate the implied log-normal volatility σ from a Black model price.
"""
function black_implied_volatility(price, strike, forward, T, call_put, min_max = (0.01, 1.00))
    return black_implied_stdev(price, strike, forward, call_put, min_max .* sqrt(T)) ./ sqrt(T)
end
