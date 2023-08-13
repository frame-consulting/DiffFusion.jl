
"""
    struct Pay <: UnaryNode
        x::Payoff
        obs_time::ModelTime
        test_times::Bool
    end

A Pay payoff allows the user to modify the observation time of
a given payoff. This is relevant for discounting.

Typically, we use Pay to specify the pay time for a payoff.
"""
struct Pay <: UnaryNode
    x::Payoff
    obs_time::ModelTime
    test_times::Bool
end

"""
    Pay(x::Payoff, pay_time::ModelTime)

Create a Pay object and check for consistency.
"""
function Pay(x::Payoff, pay_time::ModelTime)
    obs_time_x = obs_time(x)
    if pay_time < obs_time_x
        @warn "Pay time is before observation time." pay_time obs_time_x
    end
    return Pay(x, pay_time, true)
end

"""
    at(p::Pay, path::AbstractPath)

Derive payoff of the child payoff.
"""
at(p::Pay, path::AbstractPath) = at(p.x, path)

"""
    obs_time(p::Pay)

Return decorating observation time.
"""
obs_time(p::Pay) = p.obs_time

"""
    obs_times(p::Pay)

Return all observation times of the linked payoff.
"""
obs_times(p::Pay) = union(obs_times(p.x), p.obs_time)

"""
    string(p::Pay)

Formatted (and shortened) output for Pay payoff.
"""
string(p::Pay) = @sprintf("(%s @ %.2f)", string(p.x), p.obs_time)


"""
    mutable struct Cache <: UnaryNode
        x::Payoff
        path::Union{AbstractPath, Nothing}
        value::Union{AbstractVector, Nothing}
    end

A Cache payoff aims at avoiding repeated calculations of the same payoff.

If a Payoff object is referenced by several parent Payoff objects then
each call of *at()* of the parent object triggers a call of *at()* of
the child object that all return the same value(s).

A Cache payoff checks whether the payoff was already evaluated and if
yes then returns a cached value.
"""
mutable struct Cache <: UnaryNode
    x::Payoff
    path::Union{AbstractPath, Nothing}
    value::Union{AbstractVector, Nothing}
end

"""
    Cache(x::Payoff)

Create a Cache payoff from a given payoff.
"""
Cache(x::Payoff) = Cache(x, nothing, nothing)

"""
    at(p::Cache, path::AbstractPath)

Derive payoff of the child payoff only if not yet calculated.
"""
function at(p::Cache, path::AbstractPath)
    if !(p.path === path)
        p.value = at(p.x, path)
        p.path = path
    end
    return p.value
end

"""
    string(p::Cache)

Formatted (and shortened) output for Cache payoff.
"""
string(p::Cache) = @sprintf("{%s}", string(p.x))
