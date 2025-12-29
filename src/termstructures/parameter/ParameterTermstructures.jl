
"""
    abstract type PiecewiseFlatParameter <: ParameterTermstructure end

A generic vector-valued model parameter term structure with piece-wise constant
interpolation and constant extrapolation.
"""
abstract type PiecewiseFlatParameter <: ParameterTermstructure end


"""
    struct BackwardFlatParameter{T<:ModelValue} <: PiecewiseFlatParameter
        alias::String
        times::Vector{ModelTime}
        values::Matrix{T}
    end

A generic vector-valued model parameter term structure with piece-wise constant
backward-flat interpolation and constant extrapolation.
"""
struct BackwardFlatParameter{T<:ModelValue} <: PiecewiseFlatParameter
    alias::String
    times::Vector{ModelTime}
    values::Matrix{T}
end


"""
    backward_flat_parameter(
         alias::String,
         times::AbstractVector,
         values::AbstractMatrix,
         )

Create a BackwardFlatParameter object for vector-valued parameters.
"""
function backward_flat_parameter(
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
    #
    return BackwardFlatParameter(alias, Vector(times), Matrix(values))
end

"""
    backward_flat_parameter(
        alias::String,
        times::AbstractVector,
        values::AbstractVector,
        )

Create a BackwardFlatParameter object for scalar parameters.
"""
function backward_flat_parameter(
    alias::String,
    times::AbstractVector,
    values::AbstractVector,
    )
    return backward_flat_parameter(alias, times, reshape(values, (1,:)))
end


"""
    struct ForwardFlatParameter{T<:ModelValue} <: PiecewiseFlatParameter
        alias::String
        times::Vector{ModelTime}
        values::Matrix{T}
    end

A generic vector-valued model parameter term structure with piece-wise constant
forward-flat interpolation and constant extrapolation.
"""
struct ForwardFlatParameter{T<:ModelValue} <: PiecewiseFlatParameter
    alias::String
    times::Vector{ModelTime}
    values::Matrix{T}
end

"""
    forward_flat_parameter(
        alias::String,
        times::AbstractVector,
        values::AbstractMatrix,
        )

Create a ForwardFlatParameter object for vector-valued parameters.
"""
function forward_flat_parameter(
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
    #
    return ForwardFlatParameter(alias, Vector(times), Matrix(values))
end

"""
    forward_flat_parameter(
        alias::String,
        times::AbstractVector,
        values::AbstractVector,
        )

Create a ForwardFlatParameter object for scalar parameters.
"""
function forward_flat_parameter(
    alias::String,
    times::AbstractVector,
    values::AbstractVector,
    )
    return forward_flat_parameter(alias, times, reshape(values, (1,:)))
end


"""
    flat_parameter(value::ModelValue)

Create a constant BackwardFlatParameter object.
"""
function flat_parameter(
    value::ModelValue,
    )
    return backward_flat_parameter("", zeros((1)), value * ones((1,1)))
end

"""
    flat_parameter(alias::String, value::ModelValue)

Create a constant BackwardFlatParameter object.
"""
function flat_parameter(
    alias::String,
    value::ModelValue,
    )
    return backward_flat_parameter(alias, zeros((1)), value * ones((1,1)))
end

"""
    flat_parameter(value::AbstractVector)

Create a constant BackwardFlatParameter object.
"""
function flat_parameter(
    value::AbstractVector,
    )
    return backward_flat_parameter("", zeros((1)), value * [ 1.0 ]' )
end

"""
    flat_parameter(alias::String, value::AbstractVector)

Create a constant BackwardFlatParameter object.
"""
function flat_parameter(
    alias::String,
    value::AbstractVector,
    )
    return backward_flat_parameter(alias, zeros((1)), value * [ 1.0 ]' )
end

"""
    time_idx(ts::BackwardFlatParameter, t)

Find the index such that `T[idx-1] < t <= T[idx]`.
If `t` is larger than the last (or all) times `T` then return `length(T)+1`.
"""
function time_idx(ts::BackwardFlatParameter, t)
    return searchsortedfirst(ts.times, t)
end

"""
    time_idx(ts::ForwardFlatParameter, t)

Find the index such that `T[idx] >= t > T[idx+1]`.
If `t` is smaller than the first (or all) times `T` then return `0`.
"""
function time_idx(ts::ForwardFlatParameter, t)
    return searchsortedlast(ts.times, t)
end

"""
    value(ts::PiecewiseFlatParameter, result_size::TermstructureResultSize = TermstructureVector)

Return a value for constant/time-homogeneous parameters.
"""
function value(ts::PiecewiseFlatParameter, result_size::TermstructureResultSize = TermstructureVector)
    @assert ts.times == zeros((1))  # only available for trivial term structures
    if result_size == TermstructureVector
        return @view ts.values[:,1]  # flat extrapolation
    end
    if result_size == TermstructureScalar
        @assert(size(ts.values)[1] == 1)  # only available for scalar parameters
        return ts.values[1,1]
    end
    error("Unknown TermstructureResultSize")
end


"""
    value(ts::PiecewiseFlatParameter, t::ModelTime, result_size::TermstructureResultSize = TermstructureVector)

Return a value for a given observation time t.
"""
function value(ts::PiecewiseFlatParameter, t::ModelTime, result_size::TermstructureResultSize = TermstructureVector)
    k = time_idx(ts, t)
    k = max(min(k, length(ts.times)), 1) # flat extrapolation
    if result_size == TermstructureVector
        return @view ts.values[:,k]
    end
    if result_size == TermstructureScalar
        @assert(size(ts.values)[1] == 1)  # only available for scalar parameters
        return ts.values[1,k]
    end
    error("Unknown TermstructureResultSize")
end
