
"""
    model(example::OrderedDict{String,Any})

Return the hybrid model of an example.
"""
model(example::OrderedDict{String,Any}) = get_object(example, DiffFusion.SimpleModel)

"""
    correlation_holder(example::OrderedDict{String,Any})

Return the correlation holder of an example.
"""
correlation_holder(example::OrderedDict{String,Any}) = get_object(example, DiffFusion.CorrelationHolder)

"""
    context(example::OrderedDict{String,Any})

Return the context of a given example.
"""
context(example::OrderedDict{String,Any}) = get_object(example, DiffFusion.Context)

"""
    term_structures(example::OrderedDict{String,Any})

Return a dictionary of term structures for an example.
"""
function term_structures(example::OrderedDict{String,Any})
    ts_dict = Dict{String,DiffFusion.Termstructure}()
    for (key, value) in example
        if isa(value, DiffFusion.Termstructure)
            ts_dict[key] = value
        end
    end
    return ts_dict
end

"""
    simulation!(example::OrderedDict{String,Any})

Return a Monte Carlo simulation for a given example.

If no simulation exists it is created.
"""
function simulation!(example::OrderedDict{String,Any})
    for value in values(example)
        if typeof(value) == DiffFusion.Simulation
            return value
        end
    end
    @assert haskey(example, "config/simulation")
    config = example["config/simulation"]
    #
    model_ = model(example)
    ch_ = correlation_holder(example)
    #
    @assert haskey(config, "simulation_times")
    times = config["simulation_times"]
    if isa(times, AbstractDict)
        times = Vector(times["start"]:times["step"]:times["stop"])
    end
    @assert isa(times, Vector)
    #
    @assert haskey(config, "n_paths")
    n_paths = config["n_paths"]
    @assert typeof(n_paths) == Int
    #
    if haskey(config, "with_progress_bar")
        with_progress_bar = config["with_progress_bar"]
    else
        with_progress_bar = true
    end
    @assert typeof(with_progress_bar) == Bool
    #
    if haskey(config, "seed")
        brownian_increments(n_states::Int, n_paths::Int, n_times::Int) =
            DiffFusion.pseudo_brownian_increments(n_states, n_paths, n_times, config["seed"])
    else
        brownian_increments = DiffFusion.sobol_brownian_increments
    end
    sim = DiffFusion.simple_simulation(
        model_,
        ch_,
        times,
        n_paths,
        with_progress_bar = with_progress_bar,
        brownian_increments = brownian_increments,
    )
    example[DiffFusion.alias(model_) * "/simulation"] = sim
    return sim
end

"""
    path!(example::OrderedDict{String,Any})

Return a Monte Carlo path for a given example.
"""
function path!(example::OrderedDict{String,Any})
    for value in values(example)
        if typeof(value) == DiffFusion.Path
            return value
        end
    end
    sim = simulation!(example)
    ts_dict = term_structures(example)
    #
    @assert haskey(example, "config/simulation")
    config = example["config/simulation"]
    #
    ctx = context(example)
    if haskey(config, "path_interpolation")
        path_interpolation = config["path_interpolation"]
        @assert typeof(path_interpolation) == Bool
        if path_interpolation
            path_interpolation = DiffFusion.LinearPathInterpolation
        else
            path_interpolation = DiffFusion.NoPathInterpolation
        end
    else
        path_interpolation = DiffFusion.NoPathInterpolation
    end
    #
    path_ = DiffFusion.path(sim, ts_dict, ctx, path_interpolation)
    example[DiffFusion.alias(sim.model) * "/path"] = path_
    return path_
end
