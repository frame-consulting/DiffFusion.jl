
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
    dZ = brownian_increments(
        length(state_alias_Sigma(model)),
        n_paths,
        length(times) - 1,
    )
    d_Sigma = size(dZ, 1)
    #
    X = zeros(length(state_alias(model)), n_paths, length(times))
    #
    iter = 2:length(times)
    if with_progress_bar
        iter = ProgressBar(iter)
    end
    #
    idx_dict = alias_dictionary(state_alias(model))
    #
    Gamma = ch(factor_alias(model))
    #
    for k in iter
        # E[X(t) | X(s)]
        X_0 = @view X[:,:,k-1]
        X_1 = @view X[:,:,k]
        SX = model_state(X_0, idx_dict, nothing)
        #
        X_1 .= Theta_vectorized(model, times[k-1], times[k], SX)
        X_1 .= X_1 .+ H_T(model, times[k-1], times[k])' * X_0
        #
        Cov = covariance_vectorized(model, Gamma, times[k-1], times[k], SX)
        ΣdW = similar(Cov, (d_Sigma,))
        for p in 1:n_paths
            Cov_p = @view Cov[:,:,p]
            L = cholesky!(Cov_p).L
            dZ_p = @view dZ[:, p, k-1]
            mul!(ΣdW, L, dZ_p)
            X_1_p = @view X[1:d_Sigma, p, k]
            X_1_p .= X_1_p .+ ΣdW
        end
    end
    #
    if !store_brownian_increments
        dZ = nothing
    end
    #
    return Simulation(model, times, X, dZ)
end
