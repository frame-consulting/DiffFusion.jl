
"""
    abstract type SeparableHjmModel <: ComponentModel end

An abstract type for separable HJM models.

This type covers common functions for Gaussian and Quasi-Gaussian models.

The `SeparableHjmModel` is supposed to hold a constant vector-valued
`ParameterTermstructure` for mean reversion `chi` and benchmark rate
times `delta`.
"""
abstract type SeparableHjmModel <: ComponentModel end

"""
    chi_hjm(m::SeparableHjmModel)

Return vector of constant mean reversion rates.
"""
function chi_hjm(m::SeparableHjmModel)
    return m.chi()
end

"""
    benchmark_times(m::SeparableHjmModel)

Return vector of reference/benchmark times
"""
function benchmark_times(m::SeparableHjmModel)
    return m.delta()
end

"""
    H_hjm(chi::AbstractVector, s::ModelTime, t::ModelTime)

Diagonal entries of ``H(s,t)``.
"""
function H_hjm(chi::AbstractVector, s::ModelTime, t::ModelTime)
    # exp.(-chi .* (t-s))
    δt = t-s
    return [ exp(-χ * δt) for χ in chi ]
end

"""
    H_hjm(m::SeparableHjmModel, s::ModelTime, t::ModelTime)

Diagonal entries of ``H(s,t)``.
"""
function H_hjm(m::SeparableHjmModel, s::ModelTime, t::ModelTime)
    return H_hjm(chi_hjm(m), s, t)
end

"""
    G_hjm(chi::AbstractVector, s::ModelTime, t::ModelTime)

Vector function ``G(s,t)``.
"""
function G_hjm(chi::AbstractVector, s::ModelTime, t::ModelTime)
    # (1.0 .- exp.(-chi .* (t-s))) ./ chi
    δt = t-s
    # This is an unsafe implementation. Better use Taylor expansion.
    return [ (1.0 - exp(-χ * δt)) / χ for χ in chi ]
end

"""
    G_hjm(m::SeparableHjmModel, s::ModelTime, t::ModelTime)

Vector function ``G(s,t)``.
"""
function G_hjm(m::SeparableHjmModel, s::ModelTime, t::ModelTime)
    return G_hjm(chi_hjm(m), s, t)
end

"""
    G_hjm(chi::AbstractVector, s::ModelTime, T::AbstractVector)

Vector function ``G(s,t)`` as matrix of size (d,k) where
k = length(T)
"""
function G_hjm(chi::AbstractVector, s::ModelTime, T::AbstractVector)
    # This is an unsafe implementation. Better use Taylor expansion.
    return (1.0 .- exp.(-chi .* (T' .- s))) ./ chi
end

"""
    G_hjm(m::SeparableHjmModel, s::ModelTime, T::AbstractVector)

Vector function ``G(s,t)``.
"""
function G_hjm(m::SeparableHjmModel, s::ModelTime, T::AbstractVector)
    return G_hjm(chi_hjm(m), s, T)
end

"""
    benchmark_times_scaling(chi::AbstractVector, delta::AbstractVector)

Benchmark times volatility scaling matrix ``H [H^f]^{-1} = [H^f H^{-1}]^{-1}``.
"""
function benchmark_times_scaling(chi::AbstractVector, delta::AbstractVector)
    # Hf_H_inv = exp.(-delta * chi')
    Hf_H_inv = [ exp(-chi_ * delta_) for delta_ in delta, chi_ in chi ]  # beware the order of loops!
    HHfInv = inv(Hf_H_inv)
    return HHfInv
end

"""
    func_y(
        y0::AbstractMatrix,
        chi::AbstractVector,
        sigmaT::AbstractMatrix,
        s::ModelTime,
        t::ModelTime,
        )

Calculate variance/auxiliary state variable ``y(t)`` given ``y(s)=y_0``.

In this function we assume that sigma is constant over the time interval ``(s,t)``.
"""
function func_y(
    y0::AbstractMatrix,
    chi::AbstractVector,
    sigmaT::AbstractMatrix,
    s::ModelTime,
    t::ModelTime,
    )
    # chi_i_p_chi_j = chi .+ chi'
    # H_i_j = exp.(-chi_i_p_chi_j .* (t-s))
    # V = sigmaT * transpose(sigmaT)
    # G_i_j = (1. .- H_i_j) ./ chi_i_p_chi_j
    # y1 = y0 .* H_i_j .+ V .* G_i_j
    #
    # better exploit symmetry and update in-place
    # this is unsafe, better use Taylor expansion
    d = length(chi)
    δt = t - s
    return [
        y0[i,j] * exp(-(chi[i] + chi[j]) * δt) +
        sum( sigmaT[i,k] * sigmaT[j,k] for k in 1:d ) *
        (1.0 - exp(-(chi[i] + chi[j]) * δt)) / (chi[i] + chi[j])
        for i in 1:d, j in 1:d
    ]
end


"""
    _func_y(
        chi::AbstractVector,
        sigmaT::AbstractMatrix,
        s::ModelTime,
        t::ModelTime,
        )

Calculate variance/auxiliary state variable ``y(t)`` given ``y(s)=0``.

In this function we assume that sigma is constant over the time interval ``(s,t)``.
"""
function _func_y(
    chi::AbstractVector,
    sigmaT::AbstractMatrix,
    s::ModelTime,
    t::ModelTime,
    )
    # chi_i_p_chi_j = chi .+ chi'
    # H_i_j = exp.(-chi_i_p_chi_j .* (t-s))
    # V = sigmaT * transpose(sigmaT)
    # G_i_j = (1. .- H_i_j) ./ chi_i_p_chi_j
    # y1 = 0 + V .* G_i_j
    #
    # better exploit symmetry and update in-place
    # this is unsafe, better use Taylor expansion
    d = length(chi)
    δt = t - s
    return [
        sum( sigmaT[i,k] * sigmaT[j,k] for k in 1:d ) *
        (1.0 - exp(-(chi[i] + chi[j]) * δt)) / (chi[i] + chi[j])
        for i in 1:d, j in 1:d
    ]
end


"""
    func_Theta_x(
        chi::AbstractVector,
        y::Function,       # (u) -> Matrix
        sigmaT::Function,  # (u) -> Matrix
        alpha::Function,   # (u) -> Vector
        s::ModelTime,
        t::ModelTime,
        param_grid::Union{AbstractVector, Nothing},
        )

Calculate Theta function for state variable x.

In this function we assume for the interval ``(s,t)`` that
    - variance ``y(s)`` is known,
    - volatility ``σ`` is state-independent and
    - quanto adjustment alpha is state-independent.
"""
function func_Theta_x(
    chi::AbstractVector,
    y::Function,       # (u) -> Matrix
    sigmaT::Function,  # (u) -> Matrix
    alpha::Function,   # (u) -> Vector
    s::ModelTime,
    t::ModelTime,
    param_grid::Union{AbstractVector, Nothing},
    )
    theta0 = H_hjm(chi,s,t) .* (y(s) * G_hjm(chi,s,t))
    # Beware how sigmaT is specified and whether it includes rates correlation!
    # Below formula does not work unless alpha(u) includes a [D^T]^-1 term.
    f(u) = H_hjm(chi,u,t) .* (sigmaT(u) * (sigmaT(u)' * G_hjm(chi,u,t) - alpha(u)))
    # Be careful when integrating piece-wise constant vols!
    # Better split the integral if we encounter jumps in f.
    theta1 = _vector_integral(f, s, t, param_grid)
    return theta0 + theta1
end

"""
    func_Theta_x_integrate_y(
        chi::AbstractVector,
        y::Function,       # (u) -> Matrix
        sigmaT::Function,  # (u) -> Matrix
        alpha::Function,   # (u) -> Vector
        s::ModelTime,
        t::ModelTime,
        param_grid::Union{AbstractVector, Nothing},
        )

Calculate Theta function for state variable ``x``.

Avoidance of explicit ``σ^\\top σ`` dependence may help with integrating over
jumps in piece-wise constant volatility. 

In this function we assume for the interval ``(s,t)`` that
    - variance ``y`` is state-independent,
    - volatility ``σ`` is state-independent and
    - quanto adjustment ``α`` is state-independent.
"""
function func_Theta_x_integrate_y(
    chi::AbstractVector,
    y::Function,       # (u) -> Matrix
    sigmaT::Function,  # (u) -> Matrix
    alpha::Function,   # (u) -> Vector
    s::ModelTime,
    t::ModelTime,
    param_grid::Union{AbstractVector, Nothing},
    )
    # make sure sigmaT(u) does not contain D^T to avoid correlation terms twice.
    one = ones(length(chi))
    f(u) = H_hjm(chi,u,t) .* (y(u)*one - sigmaT(u) * alpha(u))
    theta = _vector_integral(f, s, t, param_grid)
    return theta
end



"""
    func_Theta_s(
        chi::AbstractVector,
        y::Function,       # (u) -> Matrix
        sigmaT::Function,  # (u) -> Matrix
        alpha::Function,   # (u) -> Vector
        s::ModelTime,
        t::ModelTime,
        param_grid::Union{AbstractVector, Nothing},
        )

Calculate Theta function for integrated state variable ``s``.

In this function we assume for the interval ``(s,t)`` that
    - variance ``y`` state-independent,
    - volatility ``σ`` is state-independent and
    - quanto adjustment ``α`` is state-independent.
"""
function func_Theta_s(
    chi::AbstractVector,
    y::Function,       # (u) -> Matrix
    sigmaT::Function,  # (u) -> Matrix
    alpha::Function,   # (u) -> Vector
    s::ModelTime,
    t::ModelTime,
    param_grid::Union{AbstractVector, Nothing},
    )
    # make sure sigmaT(u) does not contain D^T to avoid correlation terms twice.
    one = ones(length(chi))
    f(u) = G_hjm(chi,u,t)' * (y(u)*one - sigmaT(u) * alpha(u))
    theta = _scalar_integral(f, s, t, param_grid)
    return theta
end

"""
    func_Theta(
        chi::AbstractVector,
        y::Function,       # (u) -> Matrix
        sigmaT::Function,  # (u) -> Matrix
        alpha::Function,   # (u) -> Vector
        s::ModelTime,
        t::ModelTime,
        param_grid::Union{AbstractVector, Nothing},
        )

Calculate Theta function for component model state variable ``X``.

In this function we assume for the interval ``(s,t)`` that
    - variance ``y`` state-independent,
    - volatility ``σ`` is state-independent and
    - quanto adjustment ``α`` is state-independent.
"""
function func_Theta(
    chi::AbstractVector,
    y::Function,       # (u) -> Matrix
    sigmaT::Function,  # (u) -> Matrix
    alpha::Function,   # (u) -> Vector
    s::ModelTime,
    t::ModelTime,
    param_grid::Union{AbstractVector, Nothing},
    )
    return vcat(
        func_Theta_x(chi, y, sigmaT, alpha, s, t, param_grid),
        func_Theta_s(chi, y, sigmaT, alpha, s, t, param_grid),
    )
end

"""
    func_H_T(chi::AbstractVector, s::ModelTime, t::ModelTime)

Calculate ``H`` function for component model.
"""
function func_H_T(chi::AbstractVector, s::ModelTime, t::ModelTime)
    d = length(chi)
    i_ = vcat(1:d, 1:d,              d + 1)
    j_ = vcat(1:d, repeat([d+1], d), d + 1)
    v_ = vcat(H_hjm(chi,s,t), G_hjm(chi,s,t), 1)
    return sparse(i_, j_, v_)
end

"""
    func_H_T_dense(chi::AbstractVector, s::ModelTime, t::ModelTime)

Alternative ``H`` function implementation for debugging.
"""
function func_H_T_dense(chi::AbstractVector, s::ModelTime, t::ModelTime)
    H_x = hcat(Diagonal(H_hjm(chi,s,t)), zeros(length(chi)))
    H_s = hcat(G_hjm(chi,s,t)', ones(1))
    return vcat(H_x, H_s)'  # beware the transpose
end


"""
    func_Sigma_T(
        chi::AbstractVector,
        sigmaT::Function,
        s::ModelTime,
        t::ModelTime
        )

Calculate ``Σ(u)^\\top`` function for component model.

In this function we assume for the interval ``(s,t)`` that
    - volatility ``σ`` is state-independent.
"""
function func_Sigma_T(
    chi::AbstractVector,
    sigmaT::Function,
    s::ModelTime,
    t::ModelTime
    )
    f(u) = vcat(
        H_hjm(chi,u,t) .* sigmaT(u),
        G_hjm(chi,u,t)' * sigmaT(u)
    )
    return f
end
