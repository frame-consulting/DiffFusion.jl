
"""
    abstract type AbstractPath end

An AbstractPath specifies the interface for path implementations.

This aims at providing the flexibility to add other types of paths in
the future.
"""
abstract type AbstractPath end

"""
    length(p::AbstractPath)

Return the number of realisations represented by the AbstractPath
object.

We assume that model functions applied to an AbstractPath return a
vector of length(p) where p is the number realisations.
"""
function length(p::AbstractPath)
    error("AbstractPath needs to implement length method.")
end

"""
    numeraire(p::AbstractPath, t::ModelTime, curve_key::String)

Calculate the numeraire in the domestic currency.

We allow for curve-specific numeraire calculation e.g. to allow
for trade-specific discounting in AMC valuation.
"""
function numeraire(p::AbstractPath, t::ModelTime, curve_key::String)
    error("AbstractPath needs to implement numeraire method.")
end


"""
    bank_account(p::AbstractPath, t::ModelTime, key::String)

Calculate a continuous compounded bank account value.
"""
function bank_account(p::AbstractPath, t::ModelTime, key::String)
    error("AbstractPath needs to implement bank_account method.")
end


"""
    zero_bond(p::AbstractPath, t::ModelTime, T::ModelTime, key::String)

Calculate a zero coupon bond price.
"""
function zero_bond(p::AbstractPath, t::ModelTime, T::ModelTime, key::String)
    error("AbstractPath needs to implement zero_bond method.")
end


"""
    asset(p::AbstractPath, t::ModelTime, key::String)

Calculate asset price.
"""
function asset(p::AbstractPath, t::ModelTime, key::String)
    error("AbstractPath needs to implement asset method.")
end


"""
    forward_asset(p::AbstractPath, t::ModelTime, T::ModelTime, key::String)

Calculate forward asset price as expectation in T-forward measure.
"""
function forward_asset(p::AbstractPath, t::ModelTime, T::ModelTime, key::String)
    error("AbstractPath needs to implement forward_asset method.")
end


"""
    fixing(p::AbstractPath, t::ModelTime, key::String)

Return a fixing from a term structure.

This is used to handle fixings for indices etc.
"""
function fixing(p::AbstractPath, t::ModelTime, key::String)
    error("AbstractPath needs to implement fixing method.")
end

"""
    asset_convexity_adjustment(
        p::AbstractPath,
        t::ModelTime,
        T0::ModelTime,
        T1::ModelTime,
        T2::ModelTime,
        key::String
        )

Return the convexity adjustment for a YoY asset payoff.
"""
function asset_convexity_adjustment(
    p::AbstractPath,
    t::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    T2::ModelTime,
    key::String
    )
    error("AbstractPath needs to implement asset_convexity_adjustment method.")
end

"""
    forward_index(p::AbstractPath, t::ModelTime, T::ModelTime, key::String)

Expectation E_t^T[S_T] of a tradeable asset.
"""
function forward_index(p::AbstractPath, t::ModelTime, T::ModelTime, key::String)
    error("AbstractPath needs to implement forward_index method.")
end

"""
    index_convexity_adjustment(
        p::AbstractPath,
        t::ModelTime,
        T0::ModelTime,
        T1::ModelTime,
        T2::ModelTime,
        key::String
        )

Return the convexity adjustment for a YoY index payoff.
"""
function index_convexity_adjustment(
    p::AbstractPath,
    t::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    T2::ModelTime,
    key::String
    )
    error("AbstractPath needs to implement index_convexity_adjustment method.")
end


"""
    future_index(p::AbstractPath, t::ModelTime, T::ModelTime, key::String)

Expectation E_t^Q[F(T,T)] of a Future index/price.
"""
function future_index(p::AbstractPath, t::ModelTime, T::ModelTime, key::String)
    error("AbstractPath needs to implement future_index method.")
end


"""
    swap_rate_variance(
        p::AbstractPath,
        t::ModelTime,
        T::ModelTime,
        swap_times::AbstractVector,
        yf_weights::AbstractVector,
        key::String,
        )

Calculate the normal model variance of a swap rate via Gaussian
swap rate approximation.
"""
function swap_rate_variance(
    p::AbstractPath,
    t::ModelTime,
    T::ModelTime,
    swap_times::AbstractVector,
    yf_weights::AbstractVector,
    key::String,
    )
    error("AbstractPath needs to implement swap_rate_variance method.")
end


"""
    forward_rate_variance(
    p::AbstractPath,
    t::ModelTime,
    T::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    key::String,
    )

Calculate the lognormal variance for a compounding factor of a forward-looking
or backward-looking forward rate.

"""
function forward_rate_variance(
    p::AbstractPath,
    t::ModelTime,
    T::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    key::String,
    )
    error("AbstractPath needs to implement forward_rate_variance method.")
end


"""
    asset_variance(
        p::AbstractPath,
        t::ModelTime,
        T::ModelTime,
        key::String,
        )

Calculate the lognormal model variance of an asset spot price
over the time period [t,T].
"""
function asset_variance(
    p::AbstractPath,
    t::ModelTime,
    T::ModelTime,
    key::String,
    )
    error("AbstractPath needs to implement asset_variance method.")
end


"""
    @enum(
        PathInterpolation,
        NoPathInterpolation,
        LinearPathInterpolation,
    )

PathInterpolation encodes how simulated states can be interpolates.
"""
@enum(
    PathInterpolation,
    NoPathInterpolation,
    LinearPathInterpolation,
)

