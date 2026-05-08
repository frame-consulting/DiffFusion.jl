

"""
    quasi_gaussian_simulation_step!(
        X::AbstractArray,
        times::AbstractVector,
        model::QuasiGaussianModel,
        idx_dict::AbstractDict,
        Gamma::AbstractMatrix,
        dZ::AbstractArray,
        idx::Integer,   # simulate time step idx -> (idx + 1)
        )

Simulate a single Monte-Carlo time step for a QuasiGaussianModel.
"""
function quasi_gaussian_simulation_step!(
    X::AbstractArray,
    times::AbstractVector,
    model::QuasiGaussianModel,
    idx_dict::AbstractDict,
    Gamma::AbstractMatrix,
    dZ::AbstractArray,
    idx::Integer,   # simulate time step idx -> (idx + 1)
    )
    #
    @assert size(X, 2) == size(dZ, 2)  # n_paths
    @assert size(X, 3) == size(dZ, 3) + 1  # n_times
    @assert size(X, 3) == length(times)
    #
    @assert idx > 0
    @assert idx < length(times)
    #
    t_0 = times[idx]
    t_1 = times[idx + 1]
    X_0 = @view(X[:,:,idx])
    X_1 = @view(X[:,:,idx + 1])
    SX = model_state(X_0, idx_dict, nothing)
    (d_Sigma, n_paths, _) = size(dZ)
    #
    X_1 .= Theta_vectorized(model, t_0, t_1, SX)
    X_1 .= X_1 .+ H_T(model, t_0, t_1)' * X_0
    #
    Cov = covariance_vectorized(model, Gamma, t_0, t_1, SX)
    ΣdW = similar(Cov, (d_Sigma,))
    for p in 1:n_paths
        Cov_p = @view Cov[:,:,p]
        L = cholesky!(Cov_p).L
        dZ_p = @view dZ[:, p, idx]
        mul!(ΣdW, L, dZ_p)
        X_1_p = @view X[1:d_Sigma, p, idx + 1]
        X_1_p .= X_1_p .+ ΣdW
    end
end




"""
    quasi_gaussian_simulation(
        model::QuasiGaussianModel,
        ch::CorrelationHolder,
        times::AbstractVector,
        n_paths::Int;
        with_progress_bar::Bool = true,
        brownian_increments::Function = pseudo_brownian_increments,
        store_brownian_increments::Bool = false,
        )

Calculate a Monte-Carlo simulation for a Quasi-Gaussian model.

This function relies on the internal structure of the `QuasiGaussianModel`.
"""
function quasi_gaussian_simulation(
    model::QuasiGaussianModel,
    ch::CorrelationHolder,
    times::AbstractVector,
    n_paths::Int;
    with_progress_bar::Bool = true,
    brownian_increments::Function = pseudo_brownian_increments,
    store_brownian_increments::Bool = false,
    )
    #
    times = [ ModelTime(t) for t in times]  # we require ModelTime in Theta_vectorized(...)
    dZ = brownian_increments(
        length(state_alias_Sigma(model)),
        n_paths,
        length(times) - 1,
    )
    #
    X = zeros(length(state_alias(model)), n_paths, length(times))
    #
    iter = 1:length(times)-1
    if with_progress_bar
        iter = ProgressBar(iter)
    end
    #
    idx_dict = alias_dictionary(state_alias(model))
    #
    Gamma = ch(factor_alias(model))
    #
    for idx in iter
        quasi_gaussian_simulation_step!(
            X,
            times,
            model,
            idx_dict,
            Gamma,
            dZ,
            idx,
        )
    end
    #
    if !store_brownian_increments
        dZ = nothing
    end
    #
    return Simulation(model, times, X, dZ)
end
