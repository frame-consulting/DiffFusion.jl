
"""
This file includes common interfaces and wrappers to integration routines
that are used in the package.

The centralisation of these routines should simplify replacing and fine-
tuning integration routines.
"""

"""
    _intersect_interval(s::ModelTime, t::ModelTime, grid::AbstractVector)

calculate the effective integration grid.
"""
function _intersect_interval(s::ModelTime, t::ModelTime, grid::AbstractVector)
    g = union([s, t], grid)
    sort!(g)
    g = g[ g .≥ s ]
    g = g[ g .≤ t ]
    if length(g) == 1
        g = [ g[1], g[1] ]
    end
    return g
end

"""
    _norm2(x)

Calculate the 2-norm without division.

This method is required for quadgk. Julia's `norm(x)` method yields `NaN`
at zero for `ForwardDiff.Dual`s.

See also [here](https://github.com/JuliaDiff/ForwardDiff.jl/issues/785).
"""
function _norm2(x)
    return sqrt(sum(x.^2))
end

"""
    _scalar_integral(f::Any, s::ModelTime, t::ModelTime)

Calculate the integral for a scalar function f in the range [s,t].
"""
function _scalar_integral(f::Any, s::ModelTime, t::ModelTime, grid::Nothing = nothing)
    return quadgk(f, s, t, norm = _norm2)[1]
end

"""
    _scalar_integral(f::Any, s::ModelTime, t::ModelTime, grid::AbstractVector)

Calculate the integral for a scalar function f in the range [s,t] split using `grid`.
"""
function _scalar_integral(f::Any, s::ModelTime, t::ModelTime, grid::AbstractVector)
    grid = _intersect_interval(s, t, grid)
    return sum([
        quadgk(f, l, u, norm = _norm2)[1]
        for (l, u) in zip(grid[1:end-1], grid[2:end])
    ])
end


"""
    _vector_integral(f::Any, s::ModelTime, t::ModelTime)

Calculate the integral for a vector-valued function f in the range [s,t].
"""
function _vector_integral(f::Any, s::ModelTime, t::ModelTime, grid::Nothing = nothing)
    return quadgk(f, s, t, norm = _norm2)[1]
end


"""
    _vector_integral(f::Any, s::ModelTime, t::ModelTime, grid::AbstractVector)

Calculate the integral for a vector-valued function f in the range [s,t] split using `grid`..
"""
function _vector_integral(f::Any, s::ModelTime, t::ModelTime, grid::AbstractVector)
    grid = _intersect_interval(s, t, grid)
    return sum([
        quadgk(f, l, u, norm = _norm2)[1]
        for (l, u) in zip(grid[1:end-1], grid[2:end])
    ])
end
