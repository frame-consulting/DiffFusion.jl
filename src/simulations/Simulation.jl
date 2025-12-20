
"""
    struct Simulation
        model::Model
        times::AbstractVector
        X::AbstractArray
        dZ::Union{AbstractArray, Nothing}
    end

A `Simulation` object represents the result of a Monte Carlo simulation.

Elements are:
  - `model` - the model used for simulation.
  - `times` - vector of simulation times starting with 0.
  - `X` - tensor of size (`N_1`, `N_2`, `N_3`) and type `ModelValue` where
     - `N_1` is `length(m.state_alias)`,
     - `N_2` is number of Monte Carlo paths,
     - `N_3` is `length(times)`.
  - `dZ` - Brownian motion increments.
"""
struct Simulation
    model::Model
    times::AbstractVector
    X::AbstractArray
    dZ::Union{AbstractArray, Nothing}
end


"""
    simple_simulation(
        model::Model,
        ch::CorrelationHolder,
        times::AbstractVector,
        n_paths::Int;
        with_progress_bar::Bool = true,
        brownian_increments::Function = pseudo_brownian_increments,
        store_brownian_increments::Bool = false,
        )

A simple Monte Carlo simulation method assuming all model components are state-independent.
"""
function simple_simulation(
    model::Model,
    ch::CorrelationHolder,
    times::AbstractVector,
    n_paths::Int;
    with_progress_bar::Bool = true,
    brownian_increments::Function = pseudo_brownian_increments,
    store_brownian_increments::Bool = false,
    )
    @assert state_alias(model) == state_alias_Sigma(model)  # deal with general case later...
    dZ = brownian_increments(
        length(state_alias_Sigma(model)),
        n_paths,
        length(times) - 1,
    )
    X = zeros(length(state_alias(model)), n_paths, 1)
    iter = 2:length(times)
    if with_progress_bar
        iter = ProgressBar(iter)
    end
    for k in iter
        # E[X(t) | X(s)]
        X_t = Theta(model,times[k-1],times[k]) .+ H_T(model,times[k-1],times[k])' * X[:,:,k-1]
        (vol, corr) = volatility_and_correlation(model,ch,times[k-1],times[k])
        L = cholesky(corr).L
        # apply diffusion, require state_alias == state_alias_Sigma
        X_t += (sqrt(times[k] - times[k-1]) * (L .* vol)) * dZ[:,:,k-1]
        X = cat(X, X_t, dims=3)
    end
    if !store_brownian_increments
        dZ = nothing
    end
    #
    return Simulation(model, times, X, dZ)
end


"""
    diagonal_simulation(
        model::Model,
        ch::CorrelationHolder,
        times::AbstractVector,
        n_paths::Int;
        with_progress_bar::Bool = true,
        brownian_increments::Function = pseudo_brownian_increments,
        store_brownian_increments::Bool = false,
        )

A Monte Carlo simulation method assuming all model components are diagonal models.
"""
function diagonal_simulation(
    model::Model,
    ch::CorrelationHolder,
    times::AbstractVector,
    n_paths::Int;
    with_progress_bar::Bool = true,
    brownian_increments::Function = pseudo_brownian_increments,
    store_brownian_increments::Bool = false,
    )
    @assert state_alias(model) == state_alias_Sigma(model)  # deal with general case later...
    dZ = brownian_increments(
        length(state_alias_Sigma(model)),
        n_paths,
        length(times) - 1,
    )
    X = zeros(length(state_alias(model)), n_paths, 1)
    iter = 2:length(times)
    if with_progress_bar
        iter = ProgressBar(iter)
    end
    idx = alias_dictionary(state_alias(model))
    for k in iter
        # E[X(t) | X(s)]
        params = simulation_parameters(model, ch, times[k-1], times[k])
        Θ = hcat([
            Theta(model, times[k-1], times[k], model_state(X[:,p:p,k-1], idx, params))
            for p in 1:n_paths
        ]...)
        X_t = Θ + H_T(model,times[k-1],times[k])' * X[:,:,k-1]
        SX0 = model_state(zeros(length(state_alias(model)), 1), idx, params)
        (vol, corr) = volatility_and_correlation(model,ch,times[k-1],times[k], SX0)  # effectively, state-independent calculation
        SX = model_state(X[:,:,k-1], idx, params)
        Vol = diagonal_volatility(model, times[k-1], times[k], SX)
        L = cholesky(corr).L
        # apply diffusion, require state_alias == state_alias_Sigma
        X_t += sqrt(times[k] - times[k-1]) * L * dZ[:,:,k-1] .* Vol
        X = cat(X, X_t, dims=3)
    end
    if !store_brownian_increments
        dZ = nothing
    end
    #
    return Simulation(model, times, X, dZ)
end
