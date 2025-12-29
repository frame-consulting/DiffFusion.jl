
"""
    abstract type Termstructure end

An abstract term structure that provides an *alias* for identification.
"""
abstract type Termstructure end

"""
    alias(ts::Termstructure)

Return the term structure's alias.
"""
function alias(ts::Termstructure)
    return ts.alias
end


"""
    abstract type CorrelationTermstructure <: Termstructure end

An abstract correlation term structure that provides methods to
calculate instantaneous correlations.
"""
abstract type CorrelationTermstructure <: Termstructure end

"""
    correlation(ts::CorrelationTermstructure, alias1::String, alias2::String)

Return a scalar instantaneous correlation.
"""
function correlation(ts::CorrelationTermstructure, alias1::String, alias2::String)
    error("CorrelationTermstructure needs to implement correlation method.")
end

"""
    correlation(ts::CorrelationTermstructure, aliases::AbstractVector{String})

Return a symmetric matrix of instantaneous correlations.
"""
function correlation(ts::CorrelationTermstructure, aliases::AbstractVector{String})
    error("CorrelationTermstructure needs to implement correlation method.")
end

"""
    correlation(ts::CorrelationTermstructure, aliases1::AbstractVector{String}, aliases2::AbstractVector{String})

Return a matrix of instantaneous correlations, each element of `aliases1` versus each element
of `aliases2`. The size of the resulting matrix is `(length(aliases1), length(aliases2))`.
"""
function correlation(ts::CorrelationTermstructure, aliases1::AbstractVector{String}, aliases2::AbstractVector{String})
    error("CorrelationTermstructure needs to implement correlation method.")
end

"""
    (ts::CorrelationTermstructure)(args...)

Syntactic sugar for correlation call.
"""
(ts::CorrelationTermstructure)(args...) = correlation(ts, args...)

"""
    correlation(ts::CorrelationTermstructure, alias1::String, aliases2::AbstractVector{String})

Return an (1,N) matrix of instantaneous correlations.
"""
correlation(ts::CorrelationTermstructure, alias1::String, aliases2::AbstractVector{String}) = correlation(ts, [alias1], aliases2)

"""
    correlation(ts::CorrelationTermstructure, aliases1::AbstractVector{String}, alias2::String)

Return an (N, 1) matrix of instantaneous correlations.
"""
correlation(ts::CorrelationTermstructure, aliases1::AbstractVector{String}, alias2::String) = correlation(ts, aliases1, [alias2])


"""
    abstract type CreditDefaultTermstructure <: Termstructure end

An abstract credit default term structure that provides methods to calculate survival
probabilities.
"""
abstract type CreditDefaultTermstructure <: Termstructure end

"""
    survival(ts::CreditDefaultTermstructure, t::ModelTime)

Return the survival probability with observation time `t`.
"""
function survival(ts::CreditDefaultTermstructure, t::ModelTime)
    error("CreditDefaultTermstructure needs to implement survival method.")
end

"""
    (ts::CreditDefaultTermstructure)(args...)

Syntactic sugar for credit term structure call.
"""
(ts::CreditDefaultTermstructure)(args...) = survival(ts, args...)


"""
    abstract type FuturesTermstructure <: Termstructure end

An abstract futures term structure that provides methods to calculate prices of futures.
Such prices represent risk-neutral expectations of spot prices.
"""
abstract type FuturesTermstructure <: Termstructure end

"""
    future_price(ts::FuturesTermstructure, t::ModelTime)

Return the price of a future with settlement time `t`.
"""
function future_price(ts::FuturesTermstructure, t::ModelTime)
    error("FuturesTermstructure needs to implement future_price method.")
end

"""
    (ts::FuturesTermstructure)(args...)

Syntactic sugar for futures term structure call.
"""
(ts::FuturesTermstructure)(args...) = future_price(ts, args...)


"""
    abstract type InflationTermstructure <: Termstructure end

An abstract inflation term structure that provides methods to calculate forward
inflation index. Forward inflation index is a T-forward measure expectation of
(spot) inflation index values.
"""
abstract type InflationTermstructure <: Termstructure end

"""
    inflation_index(ts::InflationTermstructure, t::ModelTime)

Return the forward inflation index with observation time `t`.
"""
function inflation_index(ts::InflationTermstructure, t::ModelTime)
    error("InflationTermstructure needs to implement inflation_index method.")
end

"""
    (ts::InflationTermstructure)(args...)

Syntactic sugar for inflation term structure call.
"""
(ts::InflationTermstructure)(args...) = inflation_index(ts, args...)


"""
    abstract type ParameterTermstructure <: Termstructure end

An abstract generic parameter term structure that provides methods to retrieve
parameter values for various incarnations of signatures.
"""
abstract type ParameterTermstructure <: Termstructure end

"""
    value(ts::ParameterTermstructure)

Return a value for constant/time-homogeneous parameters.
"""
function value(ts::ParameterTermstructure)
    error("ParameterTermstructure needs to implement value method.")
end

"""
    value(ts::ParameterTermstructure, t::ModelTime)

Return a value for a given observation time `t`.
"""
function value(ts::ParameterTermstructure, t::ModelTime)
    error("ParameterTermstructure needs to implement value method.")
end

"""
    (ts::ParameterTermstructure)(args...)

Syntactic sugar for parameter call.
"""
(ts::ParameterTermstructure)(args...) = value(ts, args...)


"""
    abstract type YieldTermstructure <: Termstructure end

An abstract yield term structure that provides methods to calculate discount
factors zero rates and forward rates.
"""
abstract type YieldTermstructure <: Termstructure end

"""
    discount(ts::YieldTermstructure, t::ModelTime)

Return the discount factor with observation time `t`.
"""
function discount(ts::YieldTermstructure, t::ModelTime)
    error("YieldTermstructure needs to implement discount method.")
end

"""
    zero_rate(ts::YieldTermstructure, t0::ModelTime, t1::ModelTime)

Return the continuous compounded zero rate over a period `t0` to `t1`.
"""
function zero_rate(ts::YieldTermstructure, t0::ModelTime, t1::ModelTime)
    df0 = discount(ts, t0)
    df1 = discount(ts, t1)
    return log(df0/df1) / (t1 - t0)
end

"""
    zero_rate(ts::YieldTermstructure, t::ModelTime)

Return the continuous compounded zero rate as of today with observation time `t`.
"""
function zero_rate(ts::YieldTermstructure, t::ModelTime)
    return zero_rate(ts, 0.0, t)
end

"""
    forward_rate(ts::YieldTermstructure, t::ModelTime, dt=1.0e-6)

Return the instantaneous forward rate with observation time `t`.
"""
function forward_rate(ts::YieldTermstructure, t::ModelTime, dt=1.0e-6)
    # default implementation via finite differences
    return zero_rate(ts, t-dt, t+dt)
end

"""
    (ts::YieldTermstructure)(args...)

Syntactic sugar for discount factor call.
"""
(ts::YieldTermstructure)(args...) = discount(ts, args...)


"""
    abstract type VolatilityTermstructure <: Termstructure end

An abstract volatility term structure that provides methods to calculate
volatility values for various incarnations of signatures.
"""
abstract type VolatilityTermstructure <: Termstructure end

"""
    volatility(ts::VolatilityTermstructure, t::ModelTime)

Return a volatility for a given observation time `t`.
"""
function volatility(ts::VolatilityTermstructure, t::ModelTime)
    error("VolatilityTermstructure needs to implement volatility method.")
end

"""
    volatility(ts::VolatilityTermstructure, t::ModelTime, x::ModelValue)

Return a scalar volatility for a given observation time `t` and
underlying or strike value `x`.
"""
function volatility(ts::VolatilityTermstructure, t::ModelTime, x::ModelValue)
    error("VolatilityTermstructure needs to implement volatility method.")
end

"""
    (ts::VolatilityTermstructure)(args...)

Syntactic sugar for volatility call.
"""
(ts::VolatilityTermstructure)(args...) = volatility(ts, args...)

const _ts_epsilon = sqrt(eps())


"""
    is_constant(ts::Termstructure, s::ModelTime, t::ModelTime)

Determine whether term structure values are constant on the
intervall (s, t).
"""
function is_constant(ts::Termstructure, s::ModelTime, t::ModelTime)
    error("Termstructure needs to implement is_constant method.")
end
