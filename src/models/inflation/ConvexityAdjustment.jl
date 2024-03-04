
"Wrap function definitions for ν1² to avoid name collisions."
function _variance_t_T0(
    dom_model::GaussianHjmModel,
    for_model::GaussianHjmModel,
    ch::CorrelationHolder,
    t::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    T2::ModelTime,
    )
    #
    Σdx = Sigma_T(dom_model, t, T1)  # T1!
    Σdz = Sigma_T(dom_model, t, T0)  # T0!
    Σf = Sigma_T(for_model, t, T0)
    Gd = G_hjm(dom_model, T1, T2)
    Gf = G_hjm(for_model, T0, T1)
    Γ = correlation(ch, vcat(factor_alias(dom_model),factor_alias(for_model)))
    ΣT(u) = hcat(
        Gd' * Σdx(u)[1:end-1,:] + Σdz(u)[end:end,:],
        Gf' * Σf(u)[1:end-1,:],
    )
    f(u) = (ΣT(u) * Γ * ΣT(u)')[1,1]  # matrix-matrix multiplications
    return _scalar_integral(f, t, T0, parameter_grid([dom_model, for_model]))
end

"Wrap function definitions for ν2² to avoid name collisions."
function _variance_T0_T1(
    dom_model::GaussianHjmModel,
    for_model::GaussianHjmModel,
    ast_model::LognormalAssetModel,
    ch::CorrelationHolder,
    t::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    T2::ModelTime,
    )
    #
    Σd = Sigma_T(dom_model, t, T1)  # t!
    Σf = Sigma_T(for_model, T0, T1)
    Σfd = Sigma_T(ast_model, T0, T1)
    Gd = G_hjm(dom_model, T1, T2)
    Γ = correlation(ch, vcat(
        factor_alias(dom_model),
        factor_alias(for_model),
        factor_alias(ast_model),
        ))
    ΣT(u) = hcat(
        Gd' * Σd(u)[1:end-1,:],
        Σf(u)[end:end,:],
        - Σfd(u),
        )
    f(u) = (ΣT(u) * Γ * ΣT(u)')[1,1]  # matrix-matrix multiplications
    return _scalar_integral(f, T0, T1, parameter_grid([dom_model, for_model, ast_model]))
end

"Wrap function definitions for ν3² to avoid name collisions."
function _variance_T1_T2(
    dom_model::GaussianHjmModel,
    ch::CorrelationHolder,
    T1::ModelTime,
    T2::ModelTime,
    )
    #
    Σd = Sigma_T(dom_model, T1, T2)
    Γ = correlation(ch, factor_alias(dom_model))
    ΣT(u) = Σd(u)[end:end,:]
    f(u) = (ΣT(u) * Γ * ΣT(u)')[1,1]  # matrix-matrix multiplications
    return _scalar_integral(f, T1, T2, parameter_grid(dom_model))
end



"""
    log_asset_convexity_adjustment(
        dom_model::GaussianHjmModel,
        for_model::GaussianHjmModel,
        ast_model::LognormalAssetModel,
        t::ModelTime,
        T0::ModelTime,
        T1::ModelTime,
        T2::ModelTime,
        )

Calculate convexity adjustment for year-on-year coupons of tradeable assets.
"""
function log_asset_convexity_adjustment(
    dom_model::GaussianHjmModel,
    for_model::GaussianHjmModel,
    ast_model::LognormalAssetModel,
    t::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    T2::ModelTime,
    )
    # common terms
    yd = func_y(dom_model, t)
    yf = func_y(for_model, t)
    ch = dom_model.correlation_holder  # better check that this is the same as for the other models
    # deterministic components
    G = G_hjm(dom_model, t, T2)
    μ1 = 0.5 * G' * yd * G
    #
    G1 = G_hjm(for_model, t, T1)
    G0 = G_hjm(for_model, t, T0)
    μ2 = 0.5 * (G1' * yf * G1 - G0' * yf * G0)
    #
    G0 = G_hjm(dom_model, t, T0)
    G1 = G_hjm(dom_model, t, T1)
    μ3 = 0.5 * (G0' * yd * G0 - G1' * yd * G1)
    #
    μ4 = -Theta(dom_model, t, T0)[end]  # re-factor to avoid Θx calculation
    #
    μ5 = -G_hjm(for_model, T0, T1)' * Theta(for_model, t, T0)[1:end-1]
    #
    μ6 = -Theta(for_model, T0, T1)[end]
    #
    μ7 = -G_hjm(dom_model, T1, T2)' * Theta(dom_model, t, T1)[1:end-1]
    #
    μ8 = -Theta(dom_model, T1, T2)[end]
    #
    μ9 = Theta(ast_model, T0, T1)[1]
    #
    μ = μ1 + μ2 + μ3 + μ4 + μ5 + μ6 + μ7 + μ8 + μ9
    # variance components
    ν1² = _variance_t_T0(dom_model, for_model, ch, t, T0, T1, T2)
    ν2² = _variance_T0_T1(dom_model, for_model, ast_model, ch, t, T0, T1, T2)
    ν3² = _variance_T1_T2(dom_model, ch, T1, T2)
    #
    ν² = ν1² + ν2² + ν3²
    #
    return μ + 0.5 * ν²
end

