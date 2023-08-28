
"""
    struct ScenarioCube
        X::AbstractArray
        times::AbstractVector
        leg_aliases::AbstractVector
        numeraire_context_key::String
        discount_curve_key::Union{String,Nothing}
    end

A ScenarioCube represents the result of MC pricing results of a list
of product legs and is calculated for a list of observation times.

Elements are
 - `X` - tensor of size (`N_1`, `N_2`, `N_3`) and type `ModelValue` where
   - `N_1` is number of Monte Carlo paths,
   - `N_2` is number of time steps,
   - `N_3` is number of legs.
 - `times` - a vector representing observation times.
 - `leg_aliases` - a list of aliases (identifiers) corresponding to each leg
 - `numeraire_context_key` - the context_key of the `NumeraireEntry`; this
   label should indicate the cash flow currency.
 - `discount_curve_key` - a flag specifying whether prices in `X` are discounted
   prices (for XVA) or undiscounted prices (for CCR).

"""
struct ScenarioCube
    X::AbstractArray
    times::AbstractVector
    leg_aliases::AbstractVector
    numeraire_context_key::String
    discount_curve_key::Union{String,Nothing}
end

"""
    scenarios(
        legs::AbstractVector,
        times::AbstractVector,
        path::Path,
        discount_curve_key::Union{String,Nothing};
        with_progress_bar::Bool = true,
        )

Calculate `ScenarioCube` for a vector of `CashFlowLeg` objects and a vector of
scenario observation `times`.
"""
function scenarios(
    legs::AbstractVector,
    times::AbstractVector,
    path::Path,
    discount_curve_key::Union{String,Nothing};
    with_progress_bar::Bool = true,
    )
    #
    leg_aliases = [ alias(l) for l in legs ]
    numeraire_context_key = path.context.numeraire.context_key
    X = zeros(length(path),length(times),length(legs))
    iter = 1:length(times)
    if with_progress_bar
        iter = ProgressBar(iter)
    end
    for j in iter
        if !isnothing(discount_curve_key)
            num = numeraire(path, times[j], discount_curve_key)
        end
        for (k,leg) in enumerate(legs)
            payoffs = discounted_cashflows(leg, times[j])
            for payoff in payoffs
                X[:,j,k] += payoff(path)
            end
            if !isnothing(discount_curve_key)
                X[:,j,k] ./= num
            end
        end
    end
    return ScenarioCube(X, times, leg_aliases, numeraire_context_key, discount_curve_key)
end


"""
    join_scenarios(cube1::ScenarioCube, cube2::ScenarioCube)

Join two scenario cubes along leg-axis.
"""
function join_scenarios(cube1::ScenarioCube, cube2::ScenarioCube)
    @assert cube1.times == cube2.times
    @assert size(cube1.X)[1] == size(cube2.X)[1]  # MC paths
    @assert size(cube1.X)[2] == size(cube2.X)[2]  # times
    @assert cube1.numeraire_context_key == cube2.numeraire_context_key
    @assert cube1.discount_curve_key == cube2.discount_curve_key
    return ScenarioCube(
        cat(cube1.X, cube2.X, dims=3),
        cube1.times,
        vcat(cube1.leg_aliases, cube2.leg_aliases),
        cube1.numeraire_context_key,
        cube1.discount_curve_key,
    )
end

"""
    join_scenarios(cubes::AbstractVector{ScenarioCube})

Join a list of scenario cubes along leg-axis.
"""
function join_scenarios(cubes::AbstractVector{ScenarioCube})
    @assert length(cubes) > 0
    joint_cube = cubes[1]
    for cube in cubes[2:end]
        joint_cube = join_scenarios(joint_cube, cube)
    end
    return joint_cube
end


"""
    _binary_op_scenarios(cube1::ScenarioCube, cube2::ScenarioCube, op::Function)

Apply a binary operator to two scenario cubes.
"""
function _binary_op_scenarios(cube1::ScenarioCube, cube2::ScenarioCube, op::Function)
    @assert cube1.times == cube2.times
    # allow broadcasting along path-axis if supported by op
    @assert (size(cube1.X)[1] == size(cube2.X)[1] ) ||
            (size(cube1.X)[1] == 1) ||
            (size(cube2.X)[1] == 1)
    @assert size(cube1.X)[2] == size(cube2.X)[2]  # times must match
    # allow broadcasting along legs-axis if supported by op
    @assert (size(cube1.X)[3] == size(cube2.X)[3] ) ||
            (size(cube1.X)[3] == 1) ||
            (size(cube2.X)[3] == 1)
    # not sure if we really have to impose the following conditions...
    @assert cube1.numeraire_context_key == cube2.numeraire_context_key
    @assert cube1.discount_curve_key == cube2.discount_curve_key
    #
    if !isa(op, Broadcast.BroadcastFunction)
        op = Broadcast.BroadcastFunction(op)
    end
    #
    X = op(cube1.X, cube2.X)
    times = cube1.times
    #
    leg_aliases_1 = cube1.leg_aliases
    if length(leg_aliases_1) == 1
        leg_aliases_1 = repeat(leg_aliases_1, length(cube2.leg_aliases))
    end
    leg_aliases_2 = cube2.leg_aliases
    if length(leg_aliases_2) == 1
        leg_aliases_2 = repeat(leg_aliases_2, length(cube1.leg_aliases))
    end
    @assert length(leg_aliases_1) == length(leg_aliases_2)
    leg_aliases = [
        "(" * first * " " * string(op.f) * " " * second * ")"
        for (first, second) in zip(leg_aliases_1, leg_aliases_2)
    ]
    #
    numeraire_context_key = cube1.numeraire_context_key
    discount_curve_key = cube1.discount_curve_key
    #
    return ScenarioCube(X, times, leg_aliases, numeraire_context_key, discount_curve_key)
end


import Base.+
import Base.-
import Base.*
import Base./
(+)(x::ScenarioCube, y::ScenarioCube) = _binary_op_scenarios(x, y, +)
(-)(x::ScenarioCube, y::ScenarioCube) = _binary_op_scenarios(x, y, -)
(*)(x::ScenarioCube, y::ScenarioCube) = _binary_op_scenarios(x, y, *)
(/)(x::ScenarioCube, y::ScenarioCube) = _binary_op_scenarios(x, y, /)


"""
    interpolate_scenarios(
        t::ModelTime,
        cube::ScenarioCube,
        )

Interpolation scenarios along time axis.

We implement linear interpolation with flat extrapolation.

Other interpolations, e.g., piece-wise flat or Brownian Bridge should be incorporated here.
"""
function interpolate_scenarios(
    t::ModelTime,
    cube::ScenarioCube,
    )
    #
    if t ≤ cube.times[begin]
        return ScenarioCube(cube.X[:,begin:begin,:], [ t ], cube.leg_aliases, cube.numeraire_context_key, cube.discount_curve_key)
    end
    if t ≥ cube.times[end]
        return ScenarioCube(cube.X[:,end:end,:], [ t ], cube.leg_aliases, cube.numeraire_context_key, cube.discount_curve_key)
    end
    idx = searchsortedfirst(cube.times, t)
    @assert idx > 1
    ρ = (cube.times[idx] - t) / (cube.times[idx] - cube.times[idx-1])
    X = ρ * cube.X[:,idx-1:idx-1,:] + (1 - ρ) * cube.X[:,idx:idx,:]
    return ScenarioCube(X, [ t ], cube.leg_aliases, cube.numeraire_context_key, cube.discount_curve_key)
end


"""
    concatenate_scenarios(cubes::AbstractVector{ScenarioCube})

Concatenate a list of scenarios along time axis.
"""
function concatenate_scenarios(cubes::AbstractVector{ScenarioCube})
    @assert length(cubes) > 0
    n_paths = size(cubes[1].X)[1]
    n_legs = size(cubes[1].X)[3]
    leg_aliases = cubes[1].leg_aliases
    numeraire_context_key = cubes[1].numeraire_context_key
    discount_curve_key = cubes[1].discount_curve_key
    for c in cubes
        @assert size(c.X)[1] == n_paths
        @assert size(c.X)[3] == n_legs
        @assert c.leg_aliases == leg_aliases
        @assert c.numeraire_context_key == numeraire_context_key
        @assert c.discount_curve_key == discount_curve_key
    end
    times = vcat([c.times for c in cubes]...)
    if length(times) > 1
        @assert all(times[2:end] .> times[1:end-1])  # monotonicity
    end
    X = cat([c.X for c in cubes]..., dims=2)
    return ScenarioCube(X, times, leg_aliases, numeraire_context_key, discount_curve_key)
end
