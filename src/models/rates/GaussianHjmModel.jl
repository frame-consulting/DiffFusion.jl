
"""
    struct GaussianHjmModelVolatility
        scaling_matrix::AbstractMatrix
        sigma_f::BackwardFlatVolatility
        DfT::AbstractMatrix
    end

A dedicated matrix-valued volatility term structure for Gaussian HJM Models.
"""
struct GaussianHjmModelVolatility
    scaling_matrix::AbstractMatrix
    sigma_f::BackwardFlatVolatility
    DfT::AbstractMatrix
end

function volatility(o::GaussianHjmModelVolatility, u::ModelTime)
    # return o.scaling_matrix * (o.DfT .* o.sigma_f(u))  # beware DfT multiplication
    σ = o.sigma_f(u)
    d = length(σ)
    return [
        sum( o.scaling_matrix[i,k] * o.DfT[k,j] * σ[k] for k = 1:d )
        for i = 1:d, j = 1:d
    ]
end

"Calculate volatility matrix."
(o::GaussianHjmModelVolatility)(u::ModelTime) = volatility(o, u)


"""
    struct GaussianHjmModel <: SeparableHjmModel
        alias::String
        delta::ParameterTermstructure
        chi::ParameterTermstructure
        sigma_T::GaussianHjmModelVolatility
        y::AbstractArray
        state_alias::AbstractVector
        factor_alias::AbstractVector
        correlation_holder::Union{CorrelationHolder, Nothing}
        quanto_model::Union{AssetModel, Nothing}
        scaling_type::BenchmarkTimesScaling
    end

A Gaussian HJM model with piece-wise constant benchmark rate volatility and
constant mean reversion.
"""
struct GaussianHjmModel <: SeparableHjmModel
    alias::String
    delta::ParameterTermstructure
    chi::ParameterTermstructure
    sigma_T::GaussianHjmModelVolatility
    y::AbstractArray
    state_alias::AbstractVector
    factor_alias::AbstractVector
    correlation_holder::Union{CorrelationHolder, Nothing}
    quanto_model::Union{AssetModel, Nothing}
    scaling_type::BenchmarkTimesScaling
end

"""
    gaussian_hjm_model(
        alias::String,
        delta::ParameterTermstructure,
        chi::ParameterTermstructure,
        sigma_f::BackwardFlatVolatility,
        correlation_holder::Union{CorrelationHolder, Nothing},
        quanto_model::Union{AssetModel, Nothing},
        scaling_type::BenchmarkTimesScaling = ForwardRateScaling,
        )

Create a Gaussian HJM model.
"""
function gaussian_hjm_model(
    alias::String,
    delta::ParameterTermstructure,
    chi::ParameterTermstructure,
    sigma_f::BackwardFlatVolatility,
    correlation_holder::Union{CorrelationHolder, Nothing},
    quanto_model::Union{AssetModel, Nothing},
    scaling_type::BenchmarkTimesScaling = _default_benchmark_time_scaling,
    )
    # Check inputs
    @assert length(delta()) > 0
    @assert delta()[1] >= 0
    for k in 2:length(delta())
        @assert delta()[k] > delta()[k-1]
    end
    @assert length(chi()) == length(delta())
    @assert chi()[1] > 0
    for k in 2:length(chi())
        @assert chi()[k] > chi()[k-1]
    end
    @assert size(sigma_f(0.0)) == (length(delta()),)
    # manage aliases
    state_alias = vcat(
        [ alias * "_x_" * string(k) for k in 1:length(delta()) ],
        [ alias * "_s" ],
    )
    factor_alias = [ alias * "_f_" * string(k) for k in 1:length(delta()) ]
    # calculate consistent correlations
    DfT = Diagonal(ones(length(delta())))
    if !isnothing(correlation_holder)
        Gamma = correlation_holder(factor_alias)
        DfT = cholesky(Gamma).L
    end
    # prepare vol calculation
    scaling_matrix = benchmark_times_scaling(chi(), delta(), scaling_type)
    sigma_T = GaussianHjmModelVolatility(scaling_matrix, sigma_f, DfT)
    # pre-calculate variance 
    d = length(delta())
    y = zeros(d, d, 0)
    t0 = 0.0
    y0 = zeros(d,d)
    for k in 1:length(sigma_f.times)
        sigmaT_k = sigma_T(sigma_f.times[k])
        y = cat(y, func_y(y0, chi(), sigmaT_k, t0, sigma_f.times[k]), dims=3)
        t0 = sigma_f.times[k]
        y0 = y[:,:,k]
    end
    return GaussianHjmModel(alias, delta, chi, sigma_T, y,
        state_alias, factor_alias, correlation_holder, quanto_model, scaling_type)
end

"""
    parameter_grid(m::GaussianHjmModel)

Return a list of times representing the (joint) grid points of piece-wise
constant model parameters.

This method is intended to be used in conjunction with time-integration
mehods that require smooth integrand functions.
"""
function parameter_grid(m::GaussianHjmModel)
    return m.sigma_T.sigma_f.times
end

"""
Return the model's `CorrelationHolder`.
"""
function correlation_holder(m::GaussianHjmModel)
    return m.correlation_holder
end

"""
    state_dependent_Theta(m::GaussianHjmModel)

Return whether Theta requires a state vector input X.
"""
state_dependent_Theta(m::GaussianHjmModel) = 
    (isnothing(m.quanto_model)) ? false : state_dependent_Sigma(m.quanto_model)

"""
    state_alias_H(m::GaussianHjmModel)

Return a list of state alias strings required for (H * X) calculation.
"""
state_alias_H(m::GaussianHjmModel) = state_alias(m)

"""
    state_dependent_H(m::GaussianHjmModel)

Return whether H requires a state vector input X.
"""
state_dependent_H(m::GaussianHjmModel) = false  # COV_EXCL_LINE

"""
    state_alias_Sigma(m::GaussianHjmModel)

Return a list of state alias strings required for (Sigma(u)' Gamma Sigma(u)) calculation.
"""
state_alias_Sigma(m::GaussianHjmModel) = state_alias(m::GaussianHjmModel)

"""
    factor_alias_Sigma(m::GaussianHjmModel)

Return a list of factor alias strings required for (Sigma(u)^T Gamma Sigma(u)) calculation.
"""
factor_alias_Sigma(m::GaussianHjmModel) = factor_alias(m)

"""
    state_dependent_Sigma(m::GaussianHjmModel)

Return whether Sigma requires a state vector input X.
"""
state_dependent_Sigma(m::GaussianHjmModel) = false  # COV_EXCL_LINE


"""
    func_y(m::GaussianHjmModel, t::ModelTime)

Calculate variance/auxiliary state variable y(t).
"""
function func_y(m::GaussianHjmModel, t::ModelTime)
    d = length(m.delta())
    t_idx = time_idx(m.sigma_T.sigma_f, t)
    if t_idx == 1
        t0 = 0.0
        # y0 = 0.0
        # use a short-cut
        return _func_y(m.chi(), m.sigma_T((t0+t)/2), t0, t)
    end
    t0 = m.sigma_T.sigma_f.times[t_idx - 1]
    y0 = @view(m.y[:,:,t_idx - 1])
    return func_y(y0, m.chi(), m.sigma_T((t0+t)/2), t0, t)
end


"""
    Theta(
        m::GaussianHjmModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the deterministic drift component for simulation over the time period [s, t].
If Theta is state-dependent a state vector X must be supplied. The method returns a
vector of length(state_alias).
"""
function Theta(
    m::GaussianHjmModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Theta(m)
    y(t) = func_y(m, t)
    # make sure we do not apply correlations twice in quanto adjustment!
    sigma_T_hyb(u) = m.sigma_T.scaling_matrix .* reshape(m.sigma_T.sigma_f(u), (1,:))
    alpha = quanto_drift(m.factor_alias, m.quanto_model, s, t, X)
    return vcat(
        func_Theta_x_integrate_y(m.chi(),y,sigma_T_hyb,alpha,s,t,parameter_grid(m)),
        func_Theta_s(m.chi(),y,sigma_T_hyb,alpha,s,t,parameter_grid(m)),
    )
end


"""
    H_T(
        m::GaussianHjmModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the transposed of the convection matrix H for simulation over the time period
[s, t].
"""
function H_T(
    m::GaussianHjmModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_H(m)
    return func_H_T(m.chi(),s,t)
end


"""
    Sigma_T(
        m::GaussianHjmModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a matrix-valued function representing the volatility matrix function.
"""
function Sigma_T(
    m::GaussianHjmModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Sigma(m)
    # make sure we do not apply correlations twice!
    sigma_T_hyb(u) = m.sigma_T.scaling_matrix .* reshape(m.sigma_T.sigma_f(u), (1,:))
    return func_Sigma_T(m.chi(),sigma_T_hyb,s,t)
end


"""
    log_bank_account(m::GaussianHjmModel, model_alias::String, t::ModelTime, X::ModelState)

Retrieve the integral over sum of state variables s(t) from interest rate model.
"""
function log_bank_account(m::GaussianHjmModel, model_alias::String, t::ModelTime, X::ModelState)
    @assert alias(m) == model_alias
    return X(state_alias(m)[end])
end

"""
    log_zero_bond(m::GaussianHjmModel, model_alias::String, t::ModelTime, T::ModelTime, X::ModelState)

Calculate the zero bond term [G(t,T)' x(t) + 0.5 G(t,T)' y(t) G(t,T)]' from rates model.
"""
function log_zero_bond(m::GaussianHjmModel, model_alias::String, t::ModelTime, T::ModelTime, X::ModelState)
    @assert alias(m) == model_alias
    idx = X.idx[state_alias(m)[1]]
    d = length(state_alias(m)) - 1  # exclude s-variable
    G = G_hjm(m, t, T)
    y = func_y(m, t)
    X_ = @view(X.X[idx:idx+(d-1),:])
    GyG = sum(G[i] * sum(y[i,j] * G[j] for j in 1:d) for i in 1:d)
    return X_' * G .+ (0.5 * GyG)
end

"""
    log_zero_bonds(m::GaussianHjmModel, model_alias::String, t::ModelTime, T::AbstractVector, X::ModelState)

Calculate the zero bond terms [G(t,T)' x(t) + 0.5 G(t,T)' y(t) G(t,T)]' from rates model.
"""
function log_zero_bonds(m::GaussianHjmModel, model_alias::String, t::ModelTime, T::AbstractVector, X::ModelState)
    @assert alias(m) == model_alias
    idx = X.idx[state_alias(m)[1]]
    d = length(state_alias(m)) - 1  # exclude s-variable
    G = G_hjm(m, t, T)
    y = func_y(m, t)
    X_ = @view(X.X[idx:idx+(d-1),:])
    conv = [@view(G[:,k])' * y * @view(G[:,k]) for k in axes(G, 2) ]
    return X_' * G .+ 0.5 .* conv'
end


"""
    log_compounding_factor(
        m::GaussianHjmModel,
        model_alias::String,
        t::ModelTime,
        T1::ModelTime,
        T2::ModelTime,
        X::ModelState,
        )

Calculate the forward compounding factor term
[G(t,T2) - G(t,T1)]' x(t) + 0.5 * [G(t,T2)' y(t) G(t,T2) - G(t,T1)' y(t) G(t,T1)].

This is used for Libor forward rate calculation.
"""
function log_compounding_factor(
    m::GaussianHjmModel,
    model_alias::String,
    t::ModelTime,
    T1::ModelTime,
    T2::ModelTime,
    X::ModelState,
    )
    #
    @assert alias(m) == model_alias
    idx = X.idx[state_alias(m)[1]]
    d = length(state_alias(m)) - 1  # exclude s-variable
    G1 = G_hjm(m, t, T1)
    G2 = G_hjm(m, t, T2)
    y = func_y(m, t)
    X_ = @view(X.X[idx:idx+(d-1),:])
    G1yG1 = sum(G1[i] * sum(y[i,j] * G1[j] for j in 1:d) for i in 1:d)
    G2yG2 = sum(G2[i] * sum(y[i,j] * G2[j] for j in 1:d) for i in 1:d)
    return X_' * (G2 .- G1) .+ 0.5 * (G2yG2 - G1yG1)
end


"""
    simulation_parameters(
        m::GaussianHjmModel,
        ch::Union{CorrelationHolder, Nothing},
        s::ModelTime,
        t::ModelTime,
        )

Pre-calculate parameters that are used in state-dependent Theta and Sigma calculation.

For GaussianHjmModel there are no valuations that should be cached.
"""
function simulation_parameters(
    m::GaussianHjmModel,
    ch::Union{CorrelationHolder, Nothing},
    s::ModelTime,
    t::ModelTime,
    )
    #
    return nothing
end
