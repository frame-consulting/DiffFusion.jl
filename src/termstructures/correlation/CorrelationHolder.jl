
"""
    struct CorrelationHolder{T<:ModelValue} <: CorrelationTermstructure
        alias::String
        correlations::Dict{String, T}
        sep::String
    end

A container holding correlation values.

A CorrelationHolder allows to calculate correlation matrices
based on `String` alias keys (identifiers).
"""
struct CorrelationHolder{T<:ModelValue} <: CorrelationTermstructure
    alias::String
    correlations::Dict{String, T}
    sep::String
end


"""
    correlation_holder(
        alias::String,
        correlations::Dict,
        sep::String = "<>",
        value_type::DataType = ModelValue,
        )

Create a CorrelationHolder object from dictionary.
"""
function correlation_holder(
    alias::String,
    correlations::Dict,
    sep::String = "<>",
    )
    if (valtype(correlations) <: ModelValue)
        return CorrelationHolder(alias, correlations, sep)
    else
        # we try to convert
        value_type = Float64
        corrs = Dict{String, value_type}()
        for (key, value) in correlations
            corrs[key] = value_type(value)
        end
        return CorrelationHolder(alias, corrs, sep)
    end
end



"""
    correlation_holder(
        alias::String,
        sep::String = "<>",
        value_type::DataType = ModelValue,
        )

Create an empty CorrelationHolder object.
"""
function correlation_holder(
    alias::String,
    sep::String = "<>",
    value_type::DataType = Float64,
    )
    return correlation_holder(alias, Dict{String, value_type}(), sep)
end

"""
    correlation_key(ch::CorrelationHolder, alias1::String, alias2::String)

Derive the key for correlation dictionary from two aliases.
"""
function correlation_key(ch::CorrelationHolder, alias1::String, alias2::String)
    @assert alias1 != alias2
    if alias1 < alias2
        return alias1 * ch.sep * alias2
    else
        return alias2 * ch.sep * alias1
    end
end

"""
    set_correlation!(
        ch::CorrelationHolder,
        alias1::String,
        alias2::String,
        value::ModelValue
        )

Insert a new correlation value into CorrelationHolder.
If a correlation already exists it is overwritten.
"""
function set_correlation!(
    ch::CorrelationHolder,
    alias1::String,
    alias2::String,
    value::ModelValue
    )
    @assert isa(value, valtype(ch.correlations))
    ch.correlations[correlation_key(ch,alias1,alias2)] = value
end

"""
    get(ch::CorrelationHolder, alias1::String, alias2::String)

Implement methodology to obtain a scalar correlation from a `CorrelationHolder`.
"""
function get(ch::CorrelationHolder, alias1::String, alias2::String)
    if alias1 == alias2
        return valtype(ch.correlations)(1.0)
    end
    key = correlation_key(ch, alias1, alias2)
    if haskey(ch.correlations, key)
        return ch.correlations[key]
    end
    return valtype(ch.correlations)(0.0)
end

"""
    correlation(ch::CorrelationHolder, alias1::String, alias2::String)

Return a scalar instantaneous correlation.
"""
function correlation(ch::CorrelationHolder, alias1::String, alias2::String)
    return get(ch, alias1, alias2)
end

"""
    correlation(ch::CorrelationHolder, aliases1::AbstractVector{String}, aliases2::AbstractVector{String})

Return a matrix of instantaneous correlations, each element of aliases1 versus each element 
of aliases2. The size of the resulting matrix is (length(aliases1), length(aliases2)).
"""
function correlation(ch::CorrelationHolder, aliases1::AbstractVector{String}, aliases2::AbstractVector{String})
    M = length(aliases1)
    N = length(aliases2)
    @assert M > 0
    @assert N > 0
    corr = [ get(ch, aliases1[i], aliases2[j]) for i in 1:M, j in 1:N ]
    return corr
end

"""
    correlation(ch::CorrelationHolder, aliases::AbstractVector{String})

Return a symmetric matrix of instantaneous correlations.
"""
function correlation(ch::CorrelationHolder, aliases::AbstractVector{String})
    return correlation(ch, aliases, aliases)
end
