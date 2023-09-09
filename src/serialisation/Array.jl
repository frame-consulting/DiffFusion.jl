
"""
    array(data::AbstractVector, dims)

Convert vector `data` into d-dimensional array. Here, `d` is `length(dims)`.

Parameter `dims` is a vector or tuple of number of elements per dimension.

Data vector `data` must be of appropriate length, i.e. `length(data) == prod(dims)`.
"""
function array(data::AbstractVector, dims::Union{AbstractVector, Tuple})
    dims = Tuple(dims)  # ensure proper type for reshape
    @assert length(data) == prod(dims)
    return reshape(data, dims)
end


"""
    serialise(o::AbstractVector)

Serialise vectors.
"""
function serialise(o::AbstractVector)
    return [ serialise(e) for e in o ]
end


"""
    serialise(o::AbstractMatrix)

Serialise matrices.
"""
function serialise(o::AbstractMatrix)
    # Recall that Arrays in Julia are column-major.
    # However, for serialisation we prefer the more
    # intuitive row-major format.
    return [ serialise(e) for e in eachrow(o) ]
end


"""
    serialise(o::AbstractArray)

Serialise d-dimensional arrays.
"""
function serialise(o::AbstractArray)
    @assert length(size(o)) > 2   # otherwise it should be caught by specific functions
    d = OrderedDict{String, Any}()
    d["typename"] = string(typeof(o))
    d["constructor"] = "array"  # see method above
    d["data"] = serialise(vec(o))
    d["dims"] = serialise([ size(o)... ])
    return d
end

"""
    deserialise(o::AbstractVector, d::Union{AbstractDict, Nothing} = nothing)

De-serialise vector or matrix.
"""
function deserialise(o::AbstractVector, d::Union{AbstractDict, Nothing} = nothing)
    if (length(o) > 0) && isa(o[1], AbstractVector)
        # beware row-major serialisation
        return vcat(( deserialise(v, d)' for v in o )...)
    end
    return [ deserialise(e, d) for e in o ]
end

