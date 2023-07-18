
"""
    struct CorrelationHolder <: CorrelationTermstructure
        alias::String
        correlations::Dict
        sep::String
    end

A container holding correlation values.

A CorrelationHolder allows to calculate correlation matrices
based on `String` alias keys (identifiers).
"""
struct CorrelationHolder <: CorrelationTermstructure
    alias::String
    correlations::Dict
    sep::String
end

"""
    correlation_holder(
        alias::String,
        sep = "<>",
        )

Create an empty CorrelationHolder object.
"""
function correlation_holder(
    alias::String,
    sep = "<>",
    )
    return CorrelationHolder(alias, Dict{String, Float64}(), sep)
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
    ch.correlations[correlation_key(ch,alias1,alias2)] = value
end

"""
    get(ch::CorrelationHolder, alias1::String, alias2::String)

Implement methodology to obtain a scalar correlation from a `CorrelationHolder`.
"""
function get(ch::CorrelationHolder, alias1::String, alias2::String)
    if alias1 == alias2
        return 1.0
    end
    key = correlation_key(ch, alias1, alias2)
    if haskey(ch.correlations, key)
        return ch.correlations[key]
    end
    return 0.0
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
