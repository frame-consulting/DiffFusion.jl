
"""
    scenarios_multi_threaded(
        legs::AbstractVector,
        times::AbstractVector,
        path::Path,
        discount_curve_key::Union{String,Nothing};
        with_progress_bar::Bool = true,
        )

Multi-threaded calculation of `ScenarioCube` for a vector of `CashFlowLeg` objects and
a vector of scenario observation `times`.

Multi-threading is implemented via `Base.Threads` and the `Threads.@threads` macro.

Number of threads used for parallel calculation is specified by the environment variable
`JULIA_NUM_THREADS` or the `-t` argument when calling `julia`.

It is recommended to use this method in conjunction with thread pinning via
`ThreadPinning.jl` and `pinthreads(:cores)`.

Moreover, to avoid over-subscription in conjunction with BLAS it is recommended to
set `LinearAlgebra.BLAS.set_num_threads(1)`.
"""
function scenarios_multi_threaded(
    legs::AbstractVector,
    times::AbstractVector,
    path::DiffFusion.Path,
    discount_curve_key::Union{String,Nothing},
    )
    leg_aliases = [ DiffFusion.alias(l) for l in legs ]
    numeraire_context_key = path.context.numeraire.context_key
    #
    X = zeros(length(path), length(times), length(legs))
    Threads.@threads :static for iter in shuffle(0:(length(times) * length(legs))-1)
        j = (iter ÷ length(legs)) + 1
        k = (iter % length(legs)) + 1
        payoffs = DiffFusion.discounted_cashflows(legs[k], times[j])
        for payoff in payoffs
            X[:,j,k] .+= payoff(path)
        end
    end
    if !isnothing(discount_curve_key)
        num = zeros(length(path), length(times))
        Threads.@threads for j = 1:length(times)
            num[:, j] = DiffFusion.numeraire(path, times[j], discount_curve_key)
        end
        num = reshape(num, size(num)[1], size(num)[2], 1)  # allow broadcasting
        X ./= num
    end
    return DiffFusion.ScenarioCube(X, times, leg_aliases, numeraire_context_key, discount_curve_key)
end


@everywhere """
    _calculate_shared!(X, chunk, legs, times, path)

Auxiliary function to calculate a chunk of scenario values.

This method is supposed to be called with `SharedArray` `X`.
"""
function _calculate_shared!(X, chunk, legs, times, path)
    X_ = zeros(length(path), length(chunk))
    for idx in eachindex(chunk)
        iter = chunk[idx]
        j = (iter ÷ length(legs)) + 1
        k = (iter % length(legs)) + 1
        payoffs = discounted_cashflows(legs[k], times[j])
        for payoff in payoffs
            X_[:,idx] .+= payoff(path)
        end
    end
    for idx in eachindex(chunk)
        iter = chunk[idx]
        j = (iter ÷ length(legs)) + 1
        k = (iter % length(legs)) + 1
        X[:,j,k] .= X_[:,idx]
    end
end


"""
    scenarios_distributed(
        legs::AbstractVector,
        times::AbstractVector,
        path::DiffFusion.Path,
        discount_curve_key::Union{String,Nothing},
        )

Multi-processing (distributed) calculation of `ScenarioCube` for a vector of `CashFlowLeg` objects and
a vector of scenario observation `times`.

Multi-processing is implemented via `Distributed` module. The number of processes can be controlled
via `-p` argument when calling `julia`.



"""
function scenarios_distributed(
    legs::AbstractVector,
    times::AbstractVector,
    path::DiffFusion.Path,
    discount_curve_key::Union{String,Nothing},
    )
    leg_aliases = [ DiffFusion.alias(l) for l in legs ]
    numeraire_context_key = path.context.numeraire.context_key
    #
    n_iters = length(times) * length(legs)
    n_workers = nworkers()
    chunk_size = n_iters ÷ n_workers
    if n_iters % n_workers > 0
        chunk_size += 1
    end
    X = SharedArray{Float64}(length(path), length(times), length(legs))
    idx_chunks = Iterators.partition(shuffle(0:n_iters-1), chunk_size)
    @assert length(idx_chunks) ≤ n_workers
    @sync for (chunk, pid) in zip(idx_chunks, workers())
        @async remotecall_fetch(_calculate_shared!, pid, X, chunk, legs, times, path)
    end
    #
    if !isnothing(discount_curve_key)
        num = zeros(length(path), length(times))
        for j = 1:length(times)
            num[:, j] = numeraire(path, times[j], discount_curve_key)
        end
        num = reshape(num, size(num)[1], size(num)[2], 1)  # allow broadcasting
        X ./= num
    end
    return ScenarioCube(X, times, leg_aliases, numeraire_context_key, discount_curve_key)
end


@everywhere """
    _calculate_shared_with_threads!(X, chunk, legs, times, path)

Auxiliary function to calculate a chunk of scenario values.

This method uses multi-threading via `Threads.@threads`.

This method is supposed to be called with `SharedArray` `X`.
"""
function _calculate_shared_with_threads!(X, chunk, legs, times, path)
    X_ = zeros(length(path), length(chunk))
    Threads.@threads :static for idx in eachindex(chunk)
        iter = chunk[idx]
        j = (iter ÷ length(legs)) + 1
        k = (iter % length(legs)) + 1
        payoffs = discounted_cashflows(legs[k], times[j])
        for payoff in payoffs
            X_[:,idx] .+= payoff(path)
        end
    end
    Threads.@threads :static for idx in eachindex(chunk)
        iter = chunk[idx]
        j = (iter ÷ length(legs)) + 1
        k = (iter % length(legs)) + 1
        X[:,j,k] .= X_[:,idx]
    end
end



"""
    scenarios_parallel(
        legs::AbstractVector,
        times::AbstractVector,
        path::DiffFusion.Path,
        discount_curve_key::Union{String,Nothing},
        )

Combined multi-processing (distributed) and multi-threaded calculation of
`ScenarioCube` or a vector of `CashFlowLeg` objects and a vector of scenario
observation `times`.

Multi-processing is implemented via `Distributed` module. The number of
processes can be controlled via `-p` argument when calling `julia`.

For each distributed process, multi-threading is implemented via `Threads.@threads`.

Number of threads used for parallel calculation is specified by the environment variable
`JULIA_NUM_THREADS` or the `-t` argument when calling `julia`.

It is recommended to use this method in conjunction with thread pinning via
`ThreadPinning.jl` and `pinthreads(:cores)`.

Moreover, to avoid over-subscription in conjunction with BLAS it is recommended to
set `LinearAlgebra.BLAS.set_num_threads(1)`.


"""
function scenarios_parallel(
    legs::AbstractVector,
    times::AbstractVector,
    path::DiffFusion.Path,
    discount_curve_key::Union{String,Nothing},
    )
    leg_aliases = [ DiffFusion.alias(l) for l in legs ]
    numeraire_context_key = path.context.numeraire.context_key
    #
    n_iters = length(times) * length(legs)
    n_workers = nworkers()
    chunk_size = n_iters ÷ n_workers
    if n_iters % n_workers > 0
        chunk_size += 1
    end
    X = SharedArray{Float64}(length(path), length(times), length(legs))
    idx_chunks = Iterators.partition(shuffle(0:n_iters-1), chunk_size)
    @assert length(idx_chunks) ≤ n_workers
    @sync for (chunk, pid) in zip(idx_chunks, workers())
        @async remotecall_fetch(_calculate_shared_with_threads!, pid, X, chunk, legs, times, path)
    end
    #
    if !isnothing(discount_curve_key)
        num = zeros(length(path), length(times))
        for j = 1:length(times)
            num[:, j] = numeraire(path, times[j], discount_curve_key)
        end
        num = reshape(num, size(num)[1], size(num)[2], 1)  # allow broadcasting
        X ./= num
    end
    return ScenarioCube(X, times, leg_aliases, numeraire_context_key, discount_curve_key)
end
