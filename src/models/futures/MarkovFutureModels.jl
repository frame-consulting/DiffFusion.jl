
"""
    struct MarkovFutureModel <: SeparableHjmModel
        hjm_model::GaussianHjmModel
        state_alias::Vector{String}
        factor_alias::Vector{String}
    end

A Markov model for Future prices with piece-wise constant benchmark
price volatility and constant mean reversion.

We implement an object adapter for the `GaussianHjmModel` to re-use
implementation for common modelling parts.

The `MarkovFutureModel` differs from the `GaussianHjmModel` essentially
only by the drift Theta.

Moreover, we do not require the integrated state variable and want to
identify correlations with Future prices instead of forward rates.
"""
struct MarkovFutureModel{ModelType<:GaussianHjmModel} <: SeparableHjmModel
    hjm_model::ModelType
    state_alias::Vector{String}
    factor_alias::Vector{String}
end

"""
    markov_future_model(
        alias::String,
        delta::ParameterTermstructure,
        chi::ParameterTermstructure,
        sigma_f::BackwardFlatVolatility,
        correlation_holder::Union{CorrelationHolder, Nothing},
        quanto_model::Union{AssetModel, Nothing},
        scaling_type::BenchmarkTimesScaling = ForwardRateScaling,
        )

Create a Gausian Markov model for Future prices.
"""
function markov_future_model(
    alias::String,
    delta::ParameterTermstructure,
    chi::ParameterTermstructure,
    sigma_f::BackwardFlatVolatility,
    correlation_holder::Union{CorrelationHolder, Nothing},
    quanto_model::Union{AssetModel, Nothing},
    scaling_type::BenchmarkTimesScaling = ForwardRateScaling,
    )
    #
    hjm_model = gaussian_hjm_model(alias, delta, chi, sigma_f, correlation_holder, quanto_model, scaling_type)
    # manage aliases different to GaussianHjmModel
    state_alias  = [ alias * "_x_" * string(k) for k in 1:length(delta()) ]
    factor_alias = [ alias * "_f_" * string(k) for k in 1:length(delta()) ]  # ensure consistency with HJM correlation calculation
    return MarkovFutureModel(hjm_model, state_alias, factor_alias)
end


"""
    parameter_grid(m::MarkovFutureModel)

Return a list of times representing the (joint) grid points of piece-wise
constant model parameters.

This method is intended to be used in conjunction with time-integration
mehods that require smooth integrand functions.
"""
function parameter_grid(m::MarkovFutureModel)
    return parameter_grid(m.hjm_model)
end


"""
    chi_hjm(m::MarkovFutureModel)

Return vector of constant mean reversion rates.
"""
function chi_hjm(m::MarkovFutureModel)
    return chi_hjm(m.hjm_model)
end

"""
    benchmark_times(m::MarkovFutureModel)

Return vector of reference/benchmark times
"""
function benchmark_times(m::MarkovFutureModel)
    return benchmark_times(m.hjm_model)
end

"""
    alias(m::MarkovFutureModel)

Return the model's own alias. This is the default implementation.
"""
function alias(m::MarkovFutureModel)
    return alias(m.hjm_model)
end

"""
    state_dependent_Theta(m::MarkovFutureModel)

Return whether Theta requires a state vector input X.
"""
state_dependent_Theta(m::MarkovFutureModel) = state_dependent_Theta(m.hjm_model)

"""
    state_alias_H(m::MarkovFutureModel)

Return a list of state alias strings required for (H * X) calculation.
"""
state_alias_H(m::MarkovFutureModel) = state_alias(m)

"""
    state_dependent_H(m::MarkovFutureModel)

Return whether H requires a state vector input X.
"""
state_dependent_H(m::MarkovFutureModel) = state_dependent_H(m.hjm_model)

"""
    state_alias_Sigma(m::MarkovFutureModel)

Return a list of state alias strings required for (Sigma(u)' Gamma Sigma(u)) calculation.
"""
state_alias_Sigma(m::MarkovFutureModel) = state_alias(m::MarkovFutureModel)

"""
    factor_alias_Sigma(m::MarkovFutureModel)

Return a list of factor alias strings required for (Sigma(u)^T Gamma Sigma(u)) calculation.
"""
factor_alias_Sigma(m::MarkovFutureModel) = factor_alias(m)

"""
    state_dependent_Sigma(m::MarkovFutureModel)

Return whether Sigma requires a state vector input X.
"""
state_dependent_Sigma(m::MarkovFutureModel) = state_dependent_Sigma(m.hjm_model)


"""
    Theta(
        m::MarkovFutureModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the deterministic drift component for simulation over the time period [s, t].
If Theta is state-dependent a state vector X must be supplied. The method returns a
vector of length(state_alias).
"""
function Theta(
    m::MarkovFutureModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Theta(m)
    y(t) = func_y(m.hjm_model, t)
    # make sure we do not apply correlations twice in quanto adjustment!
    sigma_T_hyb(u) = m.hjm_model.sigma_T.scaling_matrix .* reshape(m.hjm_model.sigma_T.sigma_f(u), (1,:))
    alpha = quanto_drift(m.factor_alias, m.hjm_model.quanto_model, s, t, X)
    #
    chi = chi_hjm(m)
    one = ones(length(chi))
    #
    f(u) = begin
        σT = m.hjm_model.sigma_T(u)  # w/ correlation
        σT_hyb = sigma_T_hyb(u)      # w/o correlation
        α = alpha(u)                 # w/ correlation
        return 0.5 * H_hjm(chi,u,t) .* (y(u)*chi - σT*(σT'*one) - 2.0*σT_hyb*α)
    end
    Θ = _vector_integral(f, s, t, parameter_grid(m))
    return Θ
end


"""
    H_T(
        m::MarkovFutureModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return the transposed of the convection matrix H for simulation over the time period
[s, t].
"""
function H_T(
    m::MarkovFutureModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_H(m)
    chi = chi_hjm(m)
    return sparse(1:length(chi), 1:length(chi), H_hjm(chi,s,t))
end


"""
    Sigma_T(
        m::MarkovFutureModel,
        s::ModelTime,
        t::ModelTime,
        X::Union{ModelState, Nothing} = nothing,
        )

Return a matrix-valued function representing the volatility matrix function.
"""
function Sigma_T(
    m::MarkovFutureModel,
    s::ModelTime,
    t::ModelTime,
    X::Union{ModelState, Nothing} = nothing,
    )
    @assert isnothing(X) == !state_dependent_Sigma(m)
    chi = chi_hjm(m)
    # make sure we do not apply correlations twice!
    f(u) = H_hjm(chi,u,t) .* m.hjm_model.sigma_T.scaling_matrix .* reshape(m.hjm_model.sigma_T.sigma_f(u), (1,:))
    return f
end


"""
    log_future(m::MarkovFutureModel, alias::String, t::ModelTime, T::ModelTime, X::ModelState)

Calculate the Future price term (h(t,T)'[x(t) + 0.5y(t)(1 - h(t,T))])'.
"""
function log_future(m::MarkovFutureModel, model_alias::String, t::ModelTime, T::ModelTime, X::ModelState)
    @assert alias(m) == model_alias
    idx = X.idx[state_alias(m)[1]]
    d = length(state_alias(m))
    x = @view(X.X[idx:idx+(d-1),:])
    y = func_y(m.hjm_model, t)
    h = H_hjm(m, t, T)
    return (x .+ 0.5 .* (y * (1.0 .- h)))' * h
end
