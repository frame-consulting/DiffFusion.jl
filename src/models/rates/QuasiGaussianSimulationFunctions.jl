
"""
    struct QuasiGaussianThetaIntegrand{
            T1<:ModelValue,
            T2<:AbstractArray,
            T3<:AbstractArray,
            T4<:AbstractArray,
            T5<:QuantoDrift,
        }
        s::ModelTime
        t::ModelTime
        chi::Vector{T1}
        y0::T2
        sigmaT::T3
        sigmaT_hyb::T4
        alpha::T5
    end

A functor calculating Separable HJM drift integrand (f_x, f_s) via

```
f_x(u) = H_hjm(chi,u,t) .* (y(u)*one_ .- sigmaT(u) * alpha(u))
f_s(u) = G_hjm(chi,u,t)' * (y(u)*one_ .- sigmaT(u) * alpha(u))
```
"""
struct QuasiGaussianThetaIntegrand{
        T1<:ModelValue,
        T2<:AbstractArray,
        T3<:AbstractArray,
        T4<:AbstractArray,
        T5<:QuantoDrift,
    }
    s::ModelTime
    t::ModelTime
    chi::Vector{T1}
    y0::T2
    sigmaT::T3
    sigmaT_hyb::T4
    alpha::T5
end

"""
Evaluate `QuasiGaussianThetaIntegrand`.
"""
(o::QuasiGaussianThetaIntegrand)(u::ModelTime) = begin
    y = func_y(o.y0, o.chi, o.sigmaT, o.s, u)  # (d, d, p) array
    α = o.alpha(u)  # (d,) vector
    #
    # sigmaT_hyb(u) * alpha(u)
    σ = o.sigmaT_hyb  # abbreviation
    q = [
        sum(σ[i, j, k] * α[j] for j in axes(σ, 2))
        for i in axes(σ, 1), k = axes(σ, 3)
    ]
    # y(u)⋅1 - σ^T⋅α
    tmp = reshape(sum(y, dims=2), size(q)) .- q  # (d, p) matrix
    #
    H = reshape(H_hjm(o.chi, u, o.t), (:, 1))
    f_theta_x = H .* tmp
    #
    G = reshape(G_hjm(o.chi, u, o.t), (1, :))
    f_theta_s = G * tmp
    return vcat(f_theta_x, f_theta_s)
end


"""
    Theta_vectorized(
        m::QuasiGaussianModel,
        s::ModelTime,
        t::ModelTime,
        X::ModelState,
        )

Calculate state-dependent HJM model drift for all paths.
"""
function Theta_vectorized(
    m::QuasiGaussianModel,
    s::ModelTime,
    t::ModelTime,
    X::ModelState,
    )
    @assert s ≤ t
    # note, we cannot calculate y(u) if sigma_f changes
    sigma_f = func_sigma_f(m, s, t, X)
    (d, p) = size(sigma_f)
    #
    y0 = auxiliary_variable(m, X)
    chi = m.gaussian_model.chi()
    sigmaT = func_sigma_T(m, sigma_f)
    # make sure we do not apply correlations twice in quanto adjustment!
    sigmaT_hyb = func_sigma_T_hyb(m, sigma_f)  # (d, d, p) array
    # take into account quanto adjustment
    qm = m.gaussian_model.quanto_model
    @assert isnothing(qm) || !state_dependent_Sigma(qm)  # handle local vol later
    alpha = quanto_drift(m.gaussian_model.factor_alias, qm, s, t, nothing)
    #
    f = QuasiGaussianThetaIntegrand(s, t, chi, y0, sigmaT, sigmaT_hyb, alpha)
    theta_x_s = _vector_integral(f, s, t, parameter_grid(m))  # (d+1, p) matrix
    #
    y1 = func_y(y0, chi, sigmaT, s, t)  # (d, d, p) array
    #
    return vcat(
        theta_x_s,
        reshape(y1, (d*d, p)),
    )
end


"""
    struct QuasiGaussianModelSigma{
            T1<:ModelValue,
            T2<:AbstractArray,
        }
        s::ModelTime
        t::ModelTime
        chi::Vector{T1}
        sigmaT_hyb::T2
    end

A functor to calculate the Quasi-Gaussian hybrid model interface volatility Σ^⊤(u).

Volatility is calculated for all paths.
"""
struct QuasiGaussianModelSigma{
        T1<:ModelValue,
        T2<:AbstractArray,
    }
    s::ModelTime
    t::ModelTime
    chi::Vector{T1}
    sigmaT_hyb::T2
end


"""
Evaluate `QuasiGaussianModelSigma`.
"""
(o::QuasiGaussianModelSigma)(u::ModelTime) = begin
    H = H_hjm(o.chi, u, o.t)
    G = G_hjm(o.chi, u, o.t)
    return vcat(
        H .* o.sigmaT_hyb,
        sum(G .* o.sigmaT_hyb, dims=1),
    )
end


"""
    Sigma_T_vectorized(
        m::QuasiGaussianModel,
        s::ModelTime,
        t::ModelTime,
        X::ModelState,
        )

Create a state-dependent Sigma_T functor for all paths.
"""
function Sigma_T_vectorized(
    m::QuasiGaussianModel,
    s::ModelTime,
    t::ModelTime,
    X::ModelState,
    )
    #
    @assert s ≤ t
    chi = m.gaussian_model.chi()
    sigma_f = func_sigma_f(m, s, t, X)  # (d, p) matrix
    # make sure we do not apply correlations twice!
    sigmaT_hyb = func_sigma_T_hyb(m, sigma_f)  # (d, d, p) matrix
    return QuasiGaussianModelSigma(s, t, chi, sigmaT_hyb)
end


"""
    struct SigmaTGammaSigma{T1, T2}
        sigma_T_hyb::T1
        cholesky_L::T2
    end

A functor for the state-dependent hybrid model covariance integrand.

Integrand is calculated for all paths.
"""
struct SigmaTGammaSigma{T1, T2}
    sigma_T_hyb::T1
    cholesky_L::T2
end

"""
Evaluate `SigmaTGammaSigma`.
"""
(o::SigmaTGammaSigma)(u::ModelTime) = begin
    sigmaT = o.sigma_T_hyb(u)  # (#state_alias_Sigma, #factor_alias_Sigma, p) array
    (d_state, d_factor, p) = size(sigmaT)
    #
    L = o.cholesky_L
    #
    sigmaT_L = similar(sigmaT, (d_state, d_factor))
    sigmaT_Γ_sigma = similar(sigmaT, (d_state, d_state, p))
    #
    for k in axes(sigmaT, 3)
        sigmaT_k = @view sigmaT[:, :, k]
        sigmaT_Γ_sigma_k = @view sigmaT_Γ_sigma[:,:,k]
        mul!(sigmaT_L, sigmaT_k, L)
        mul!(sigmaT_Γ_sigma_k, sigmaT_L, sigmaT_L')
    end
    return sigmaT_Γ_sigma
end



"""
    covariance_vectorized(
         m::QuasiGaussianModel,
         Gamma::AbstractMatrix,
         s::ModelTime,
         t::ModelTime,
         X::ModelState,
         )

Calculate state-dependent covariance for all paths.
"""
function covariance_vectorized(
    m::QuasiGaussianModel,
    Gamma::AbstractMatrix,
    s::ModelTime,
    t::ModelTime,
    X::ModelState,
    )
    d = length(factor_alias_Sigma(m))
    @assert size(Gamma) == (d, d)
    f = SigmaTGammaSigma(
        Sigma_T_vectorized(m, s, t, X),
        cholesky(Gamma).L,
    )
    cov = _vector_integral(f, s, t, parameter_grid(m))
    return cov
end
