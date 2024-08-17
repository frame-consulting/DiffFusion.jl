


"""
    up_hit_probability(u, w0, w1, ν²)

Return the probablity that a Brownian motion W(t) hits an upper barrer level `u`
given that W(t0) = w0, w(t1) = w1 and variance of W(t1) conditional on W(T0) is
ν².

Formula is derived from S. Shreve, Stochastic Calculus for Finance II,
Corollary 3.7.4.
"""
function up_hit_probability(u, w0, w1, ν²)
    return exp.(-2.0 .* (u .- min.(w0, u)) .* (u .- min.(w1, u)) ./ ν²)
end


"""
    down_hit_probability(d, w0, w1, ν²)

Return the probablity that a Brownian motion W(t) hits a lower barrer level `d`
given that W(t0) = w0, w(t1) = w1 and variance of W(t1) conditional on W(T0) is
ν².

Formula is derived from S. Shreve, Stochastic Calculus for Finance II,
Corollary 3.7.4. and applied to -W(t).
"""
function down_hit_probability(d, w0, w1, ν²)
    return exp.(-2.0 .* (max.(w0, d) .- d) .* (max.(w1, d) .- d) ./ ν²)
end


"""
    barrier_no_hit_probability(
        barrier_level,
        barrier_direction,
        brownian_levels::AbstractMatrix,
        brownian_variances::AbstractMatrix,
        )

Calculate the (path-wise) probability that a Brownian motion W(t) does
*not* hit an upper or lower barrier level given a list of observations.

`barrier_level` is a scalar value.

`barrier_direction` is +1 for down-barrier and -1 for up-barrier.

`brownian_levels` is of size (p, n). Here, p is the number of
simulated Brownian motion paths and n is the number of discrete
observations.

`brownian_variances` is of size (p, n-1). That is, we allow path-
dependent variance. For non-path-dependence variance, use a
matrix with p=1.
"""
function barrier_no_hit_probability(
    barrier_level,
    barrier_direction,
    brownian_levels::AbstractMatrix,
    brownian_variances::AbstractMatrix,
    )
    # ensure broadcasting
    p = max(size(brownian_levels, 1), size(brownian_variances, 1))
    @assert size(brownian_levels, 1) == p || size(brownian_levels, 1) == 1
    @assert size(brownian_variances, 1) == p || size(brownian_variances, 1) == 1
    #
    @assert size(brownian_levels, 2) ≥ 2
    @assert size(brownian_levels, 2) == size(brownian_variances, 2) + 1
    #
    @assert barrier_direction in (-1, 1)
    #
    if barrier_direction == -1
        hit_probability_func = up_hit_probability
    else
        hit_probability_func = down_hit_probability
    end
    no_hit = ones(p)
    for k in 1:(size(brownian_levels, 2) - 1)
        hit_prob = hit_probability_func(
            barrier_level,
            brownian_levels[:, k],
            brownian_levels[:, k+1],
            brownian_variances[:, k],
        )
        no_hit = no_hit .* (1.0 .- hit_prob)
    end
    return no_hit
end
