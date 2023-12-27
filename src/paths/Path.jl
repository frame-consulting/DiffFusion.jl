
"""
    struct Path <: AbstractPath
        sim::Simulation
        ts_dict::Dict{String,<:Termstructure}
        state_alias_dict::Dict{String,Int}
        context::Context
        interpolation::PathInterpolation
    end

A Path combines a model, simulated model states and term structures. The interface
to market references is established by a valuation context.

Paths are used by payoffs to calculate simulated zero bonds, asset prices
and further building blocks of financial instrument payoffs.
"""
struct Path <: AbstractPath
    sim::Simulation
    ts_dict::Dict{String,<:Termstructure}
    state_alias_dict::Dict{String,Int}
    context::Context
    interpolation::PathInterpolation
end

"""
    _check_path_setup(
        sim::Simulation,
        ts_dict::Dict{String,Termstructure},
        cxt::Context,
        )

Check for consistent path inputs.

We define an extra function in order to avoid chain rule issues with
automatic differentiation.
"""
function _check_path_setup(
    sim::Simulation,
    ts_dict::Dict{String,<:Termstructure},
    cxt::Context,
    )
    # all referenced models need to be available
    @assert isnothing(cxt.numeraire.model_alias) || cxt.numeraire.model_alias in model_alias(sim.model)
    for entry in values(cxt.rates)
        @assert isnothing(entry.model_alias) || entry.model_alias in model_alias(sim.model)
    end
    for entry in values(cxt.assets)
        @assert isnothing(entry.asset_model_alias) || entry.asset_model_alias in model_alias(sim.model)
        @assert isnothing(entry.domestic_model_alias) || entry.domestic_model_alias in model_alias(sim.model)
        @assert isnothing(entry.foreign_model_alias) || entry.foreign_model_alias in model_alias(sim.model)
    end
    # keys and value aliases must be consistent
    for (key, ts) in ts_dict
        @assert key == alias(ts)
    end
    # all referenced term structures need to be available
    for alias in unique(values(cxt.numeraire.termstructure_dict))
        @assert alias in keys(ts_dict)
        @assert isa(ts_dict[alias], YieldTermstructure)
    end
    for entry in values(cxt.rates)
        for alias in unique(values(entry.termstructure_dict))
            @assert alias in keys(ts_dict)
            @assert isa(ts_dict[alias], YieldTermstructure)
        end
    end
    for entry in values(cxt.assets)
        @assert entry.asset_spot_alias in keys(ts_dict)
        @assert isa(ts_dict[entry.asset_spot_alias], ParameterTermstructure)
        for alias in unique(values(entry.domestic_termstructure_dict))
            @assert alias in keys(ts_dict)
            @assert isa(ts_dict[alias], YieldTermstructure)
        end
        for alias in unique(values(entry.foreign_termstructure_dict))
            @assert alias in keys(ts_dict)
            @assert isa(ts_dict[alias], YieldTermstructure)
        end
    end
    for entry in values(cxt.forward_indices)
        @assert entry.forward_index_alias in keys(ts_dict)
        @assert isa(ts_dict[entry.forward_index_alias], ParameterTermstructure)
    end
    for entry in values(cxt.future_indices)
        @assert entry.future_index_alias in keys(ts_dict)
        @assert isa(ts_dict[entry.future_index_alias], ParameterTermstructure)
    end
    for entry in values(cxt.fixings)
        @assert entry.termstructure_alias in keys(ts_dict)
        @assert isa(ts_dict[entry.termstructure_alias], ParameterTermstructure)
    end
end

"""
    path(
        sim::Simulation,
        ts_dict::Dict{String,<:Termstructure},
        cxt::Context,
        ip::PathInterpolation = NoPathInterpolation
        )

Create a Path object.
"""
function path(
    sim::Simulation,
    ts_dict::Dict{String,<:Termstructure},
    cxt::Context,
    ip::PathInterpolation = NoPathInterpolation
    )
    _check_path_setup(sim, ts_dict, cxt)
    state_alias_dict = alias_dictionary(state_alias(sim.model))
    return Path(sim, ts_dict, state_alias_dict, cxt, ip)
end

"""
    _check_unique_ts(ts_alias::AbstractVector)

Check for consistent term structure inputs to path.

We define an extra function in order to avoid chain rule issues with
automatic differentiation.
"""
function _check_unique_ts(ts_alias::AbstractVector)
    @assert length(ts_alias) == length(unique(ts_alias))
end

"""
    path(
        sim::Simulation,
        ts::Vector{Termstructure},
        cxt::Context,
        ip::PathInterpolation = NoPathInterpolation
        )

Create a Path object from a list of term structures.
"""
function path(
    sim::Simulation,
    ts::Vector{<:Termstructure},
    cxt::Context,
    ip::PathInterpolation = NoPathInterpolation
    )
    #
    ts_alias = [ alias(ts_) for ts_ in ts ]
    _check_unique_ts(ts_alias)
    #
    ts_dict = Dict{String,Termstructure}(((alias(ts_), ts_) for ts_ in ts))
    return path(sim, ts_dict, cxt, ip)
end

"""
    length(p::Path)

Derive the number of realisations from the linked simulation.
"""
function length(p::Path)
    return size(p.sim.X)[2]
end

"""
    state_variable(sim::Simulation, t::ModelTime, ip::PathInterpolation)

Derive a state variable for a given observation time.
"""
function state_variable(sim::Simulation, t::ModelTime, ip::PathInterpolation)
    eps = 0.5 / 365  # we want to give a bit tolerance in avoiding interpolation
    idx = searchsortedfirst(sim.times, t)
    if idx <= length(sim.times) && t > sim.times[idx] - eps
        return @view sim.X[:,:,idx]
    end
    if idx > 1 && t < sim.times[idx-1] + eps
        return @view sim.X[:,:,idx-1]
    end
    # if we end up here we need some interpolation/extrapolation
    @assert ip != NoPathInterpolation
    # we assume constant extrapolation
    if idx == 1
        return @view sim.X[:,:,idx]
    end
    if idx > length(sim.times)
        return @view sim.X[:,:,idx-1]
    end
    # now we have 1 < idx <= length(sim.times)
    if ip == LinearPathInterpolation
        rho = (t - sim.times[idx-1]) / (sim.times[idx] - sim.times[idx-1])
        return rho .* @view(sim.X[:,:,idx]) .+ (1.0-rho) .* @view(sim.X[:,:,idx-1])
    end
    error("Unknown PathInterpolation.")
end
