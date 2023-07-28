
"""
    pseudo_brownian_increments(
        n_states::Int,
        n_paths::Int,
        n_times::Int,  # without zero
        seed::Int = 271828182846,
        )

A simple method to generate Brownian motion increments.
"""
function pseudo_brownian_increments(
    n_states::Int,
    n_paths::Int,
    n_times::Int,  # without zero
    seed::Int = 271828182846,
    )
    Random.seed!(seed)
    dist = Normal()
    return rand( dist, (n_states, n_paths, n_times) )
end

"""
    sobol_brownian_increments(
        n_states::Int,
        n_paths::Int,
        n_times::Int,  # without zero
        )

Generate Brownian motion increments via Sobol sequence.
"""
function sobol_brownian_increments(
    n_states::Int,
    n_paths::Int,
    n_times::Int,  # without zero
    )
    seq = SobolSeq(n_states * n_times)
    seq = skip(seq, n_paths)
    U = zeros(n_states, n_paths, n_times)
    for p in 1:n_paths
        U[:,p,:] = reshape(next!(seq), (n_states,n_times))
    end
    m = mean(U, dims=2)
    U = U .- reshape(m, (n_states,1,n_times)) .+ 0.5
    return quantile.(Normal(), U)
end

