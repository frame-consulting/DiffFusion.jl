
"""
    struct CorrelationHolder <: CorrelationTermstructure
        alias::String
        correlations::Dict{String, ModelValue}
        sep::String
        value_type::Type
    end

A container holding correlation values.

A CorrelationHolder allows to calculate correlation matrices
based on `String` alias keys (identifiers).

`value_type` specifies the type of correlation entries. This ensures that
all values are of consistent type. This feature is required for correlation
sensitivity calculation.
"""
struct CorrelationHolder <: CorrelationTermstructure
    alias::String
    correlations::Dict{String, ModelValue}
    sep::String
    value_type::Type
end


"""
    correlation_holder(
        alias::String,
        correlations::Dict,
        sep = "<>",
        value_type = ModelValue,
        )

Create a CorrelationHolder object from dictionary.
"""
function correlation_holder(
    alias::String,
    correlations::Dict,
    sep = "<>",
    value_type = ModelValue,
    )
    for (key, value) in correlations
        @assert isa(value, value_type)
    end
    return CorrelationHolder(alias, correlations, sep, value_type)
end



"""
    correlation_holder(
        alias::String,
        sep = "<>",
        value_type = ModelValue,
        )

Create an empty CorrelationHolder object.
"""
function correlation_holder(
    alias::String,
    sep = "<>",
    value_type = ModelValue,
    )
    return correlation_holder(alias, Dict{String, value_type}(), sep, value_type)
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
    @assert isa(value, ch.value_type)
    ch.correlations[correlation_key(ch,alias1,alias2)] = value
end

"""
    get(ch::CorrelationHolder, alias1::String, alias2::String)

Implement methodology to obtain a scalar correlation from a `CorrelationHolder`.
"""
function get(ch::CorrelationHolder, alias1::String, alias2::String)
    if alias1 == alias2
        return ch.value_type(1.0)
    end
    key = correlation_key(ch, alias1, alias2)
    if haskey(ch.correlations, key)
        return ch.correlations[key]
    end
    return ch.value_type(0.0)
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
