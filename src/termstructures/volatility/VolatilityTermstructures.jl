
"""
    struct BackwardFlatVolatility <: VolatilityTermstructure
        alias::String
        times::AbstractVector
        values::AbstractMatrix
    end

A vector-valued volatility term structure with piece-wise constant
(backward-flat) interpolation and constant extrapolation.
"""
struct BackwardFlatVolatility <: VolatilityTermstructure
    alias::String
    times::AbstractVector
    values::AbstractMatrix
end

"""
    backward_flat_volatility(
        alias::String,
        times::AbstractVector,
        values::AbstractMatrix,
        )

Create a BackwardFlatVolatility object for vector-valued volatility.

Volatility values are of size (n_vols, n_times).
"""
function backward_flat_volatility(
    alias::String,
    times::AbstractVector,
    values::AbstractMatrix,
    )
    @assert(size(values)[1] > 0)
    @assert(size(values)[2] > 0)
    @assert(size(values)[2] == size(times)[1])
    for k in 1:length(times)-1
        @assert(times[k]<times[k+1])
    end
    for idx in eachindex(values)
        @assert(values[idx] >= 0.0)
    end
    #
    return BackwardFlatVolatility(alias, times, values)
end

"""
    backward_flat_volatility(
        alias::String,
        times::AbstractVector,
        values::AbstractVector,
        )

Create a BackwardFlatVolatility object for scalar volatility.
"""
function backward_flat_volatility(
    alias::String,
    times::AbstractVector,
    values::AbstractVector,
    )
    return backward_flat_volatility(alias, times, reshape(values, (1,:)))
end

"""
    flat_volatility(alias::String, value)

Create a BackwardFlatVolatility object for a flat volatility.
"""
function flat_volatility(
    alias::String,
    value::ModelValue,
    )
    return backward_flat_volatility(alias, zeros((1)), value * ones((1,1)))
end


"""
    flat_volatility(alias::String, value)

Create a BackwardFlatVolatility object for a flat volatility.
"""
function flat_volatility(
    value::ModelValue,
    )
    return flat_volatility("", value)
end


"""
    time_idx(ts::BackwardFlatVolatility, t)

Find the index such that `T[idx-1] < t <= T[idx]`.
If `t` is larger than the last (or all) times `T` then return `length(T)+1`.
"""
function time_idx(ts::BackwardFlatVolatility, t)
    return searchsortedfirst(ts.times, t)
end


"""
    volatility(ts::BackwardFlatVolatility, t::ModelTime, result_size::TermstructureResultSize = TermstructureVector)

Return a vector of volatilities for a given observation time t.
"""
function volatility(ts::BackwardFlatVolatility, t::ModelTime, result_size::TermstructureResultSize = TermstructureVector)
    k = time_idx(ts, t)
    if result_size == TermstructureVector
        return @view ts.values[:,min(k, length(ts.times))]  # flat extrapolation
    end
    if result_size == TermstructureScalar
        @assert(size(ts.values)[1] == 1)  # only available for scalar vols
        return ts.values[1,min(k, length(ts.times))]  # flat extrapolation
    end
end
