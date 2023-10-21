
"""
    bachelier_price(strike, forward, nu, call_put)

Calculate Vanilla option price ``V`` in Bachelier model.

Argument `strike` (``K``) represents the option strike, `forward` (``F``) is the
forward price of the underlying ``S``, i.e. ``F = E[S(T)]`` in the respective
pricing measure.

Argument `nu` represents the standard deviation of the forward price. For
annualised normal volatility σ, we have `ν = σ √T`. Finally, `call_put`
is the call (+1) or put (-1) option flag.
"""
function bachelier_price(strike, forward, nu, call_put)
    intrinsic_value = max.(call_put * (forward .- strike), 0.0)
    h = call_put * (forward .- strike) ./ nu
    option_value = nu .* (h .* cdf.(Normal(), h) .+ pdf.(Normal(), h))
    return (nu .> 0.0) .* option_value + (nu .<= 0.0) .* intrinsic_value
end

"""
    bachelier_price(strike, forward, σ, T, call_put)

Calculate Vanilla option price ``V`` in Bachelier model with volatility parameter.
"""
bachelier_price(strike, forward, σ, T, call_put) = bachelier_price(strike, forward, σ * sqrt(T), call_put)


"""
    bachelier_vega(strike, forward, nu)

Calculate Vanilla option Vega in Bachelier model.

Here, Vega is calculated as ``dV / d ν``.
"""
function bachelier_vega(strike, forward, nu)
    h = (forward .- strike) ./ nu
    return (nu .> 0.0) .* pdf.(Normal(), h)
end

"""
    bachelier_vega(strike, forward, σ, T)

Calculate Vanilla option Vega in Bachelier model with volatility parameter.

Here, Vega is calculated as ``dV / dσ``.
"""
bachelier_vega(strike, forward, σ, T) = bachelier_vega(strike, forward, σ * sqrt(T)) * sqrt(T)


"""
    bachelier_implied_stdev(price, strike, forward, call_put, min_max = (1.0e-4, 6.0e-2))

Calculate the implied normal standard deviation ν from a Bachelier model price.
"""
function bachelier_implied_stdev(price, strike, forward, call_put, min_max = (1.0e-4, 6.0e-2))
    f(nu) = bachelier_price(strike, forward, nu, call_put) - price
    nu = find_zero(f, min_max, Roots.Brent(), xatol=1.0e-8)
    return nu
end

"""
    bachelier_implied_volatility(price, strike, forward, T, call_put, min_max = (0.0001, 0.02))

Calculate the implied normal volatility σ from a Bachelier model price.
"""
function bachelier_implied_volatility(price, strike, forward, T, call_put, min_max = (0.0001, 0.02))
    return bachelier_implied_stdev(price, strike, forward, call_put, min_max .* sqrt(T)) / sqrt(T)
end
