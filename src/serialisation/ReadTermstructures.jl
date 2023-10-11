
"""
    _read_csv_data(source, delim::AbstractChar)

Read data_cells and header_cells from CSV file via `DelimitedFiles.readdlm`
and check for valid result before return.

Arguments `source` and `delim` are passed on to `DelimitedFiles.readdlm`.
"""
function _read_csv_data(source, delim::AbstractChar)
    (data_cells, header_cells) = readdlm(
        source,
        delim,
        header = true,
        comments = true,
        comment_char = '#',
    )
    #
    @assert isa(data_cells, Matrix{Float64})
    @assert isa(header_cells, Matrix{AbstractString})
    @assert size(header_cells, 1) == 1
    @assert size(header_cells, 2) > 1
    @assert size(header_cells, 2) == size(data_cells, 2)
    @assert size(data_cells, 1) > 0
    return (data_cells, header_cells)
end


"""
    _create_scalar_valued_termstructures(
        data_cells::Matrix{Float64},
        header_cells::Matrix{AbstractString},
        constructor::Function,
        )

Create a list of `Termstructures` from `data_cells` and `header_cells`
using the `constructor` function.

Resulting term structures are assumed to be scalar-valued term structures,
i.e. curves.
"""
function _create_scalar_valued_termstructures(
    data_cells::Matrix{Float64},
    header_cells::Matrix{AbstractString},
    constructor::Function,
    )
    #
    return [
        constructor(String(header_cells[1,k]), data_cells[:,1], data_cells[:,k])
        for k in 2:size(data_cells, 2)
    ]
end


"""
    _create_vector_valued_termstructure(
        data_cells::Matrix{Float64},
        header_cells::Matrix{AbstractString},
        constructor::Function,
        )

Create a single `Termstructure` from `data_cells` and `header_cells`
using the `constructor` function.

Termstructure `alias` is read from the first data column header.

Resulting term structures are typically vector-valued term structures.
"""
function _create_vector_valued_termstructure(
    data_cells::Matrix{Float64},
    header_cells::Matrix{AbstractString},
    constructor::Function,
    )
    #
    return constructor(String(header_cells[1,2]), data_cells[:,1], data_cells[:,2:end]')
end



"""
    read_parameters(
        source,
        delim::AbstractChar,
        param_func::Function = forward_flat_parameter,
        )

Read times and values from CSV file and create scalar-valued
ParameterTermstructures.

Arguments `source` and `delim` are passed on to `DelimitedFiles.readdlm`.

`constructor` is the constructor called to create the term structure.
It is used to apply method to read `ForwardFlatParameter` and
`BackwardFlatParameter`.
"""
function read_parameters(
    source,
    delim::AbstractChar,
    constructor::Function = forward_flat_parameter,
    )
    #
    (data_cells, header_cells) = _read_csv_data(source, delim)
    return _create_scalar_valued_termstructures(
        data_cells,
        header_cells,
        constructor,
    )
end


"""
    read_volatilities(
        source,
        delim::AbstractChar,
        )

Read times and values from CSV file and create scalar-valued
BackwardFlatVolatility.

Arguments `source` and `delim` are passed on to `DelimitedFiles.readdlm`.
"""
function read_volatilities(
    source,
    delim::AbstractChar,
    )
    #
    (data_cells, header_cells) = _read_csv_data(source, delim)
    return _create_scalar_valued_termstructures(
        data_cells,
        header_cells,
        backward_flat_volatility,
    )
end


"""
    read_volatility(
        source,
        delim::AbstractChar,
        )

Read times and values from CSV file and create a single vector-valued
BackwardFlatVolatility.

Arguments `source` and `delim` are passed on to `DelimitedFiles.readdlm`.

Termstructure `alias` is read from the first data column header.
"""
function read_volatility(
    source,
    delim::AbstractChar,
    )
    #
    (data_cells, header_cells) = _read_csv_data(source, delim)
    return _create_vector_valued_termstructure(
        data_cells,
        header_cells,
        backward_flat_volatility,
    )
end


"""
    read_zero_curves(
        source,
        delim::AbstractChar,
        method_alias::String = "LINEAR"
        )

Read times and values from CSV file and create ZeroCurve.

Arguments `source` and `delim` are passed on to `DelimitedFiles.readdlm`.

`method_alias` is the interpolation string used in `interpolation_methods`.
"""
function read_zero_curves(
    source,
    delim::AbstractChar,
    method_alias::String = "LINEAR"
    )
    #
    (data_cells, header_cells) = _read_csv_data(source, delim)
    constructor(alias, times, values) = zero_curve(alias, times, values, method_alias)
    return _create_scalar_valued_termstructures(
        data_cells,
        header_cells,
        constructor,
    )
end


"""
    read_correlations(
        source,
        delim::AbstractChar,
        )

Read factor aliases and correlation values and setup a `CorrelationHolder`.

Arguments `source` and `delim` are passed on to `DelimitedFiles.readdlm`.
"""
function read_correlations(
    source,
    delim::AbstractChar,
    )
    #
    (data_cells, header_cells) = readdlm(
        source,
        delim,
        header = true,
        comments = true,
        comment_char = '#',
    )
    #
    @assert isa(data_cells, Matrix{Any})
    @assert isa(header_cells, Matrix{AbstractString})
    @assert size(header_cells, 1) == 1
    @assert size(header_cells, 2) == 3
    @assert size(header_cells, 2) == size(data_cells, 2)
    @assert size(data_cells, 1) > 0
    #
    ch = correlation_holder(String(header_cells[1,3]))
    for k in axes(data_cells, 1)
        set_correlation!(ch, String(data_cells[k,1]), String(data_cells[k,2]), data_cells[k,3])
    end
    return ch
end
