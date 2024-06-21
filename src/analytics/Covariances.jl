

"""
    reference_rate_scaling(
        context_key::String,
        term::ModelTime,
        mdl::Model,
        ctx::Context
        )

Return the scaling vector of a reference rate.

A reference rate is specified as a stochastic process random variable
`Y = A' X + b`. Here, `X` reprsents the model state variable, `A` is
the resulting scaling vector and `b` is a deterministic function (not
relevant for this purpose).

Reference rates are continuous compounded zero rates and FX rates (or
asset prices). Reference rates are identified by a `context_key`. In
addition, zero rates are specified by a positive `term`. For FX rates
we require `term` equal to zero.

Reference rates for other asset classes are to be added.

The model context `ctx` is used to identify corresponding model parameters
and state variables of the `model`.
"""
function reference_rate_scaling(
    context_key::String,
    term::ModelTime,
    mdl::Model,
    ctx::Context
    )
    #
    if context_key in keys(ctx.rates)
        # we model a zero rate
        @assert term > 0.0
        model_alias = ctx.rates[context_key].model_alias
        @assert !isnothing(model_alias)
        if isa(mdl, SeparableHjmModel)
            hjm_mdl = mdl
        elseif isa(mdl, CompositeModel)
            hjm_mdl = mdl.models[mdl.model_dict[model_alias]]
            @assert isa(hjm_mdl, SeparableHjmModel)
        else
            error("Cannot calculate scaling for model " * model_alias * ".")
        end
        G = G_hjm(hjm_mdl, 0.0, term)
        #
        s_alias = state_alias(mdl)
        first_alias = state_alias(hjm_mdl)[begin]
        idx = findall(x->x==first_alias, s_alias)[begin]
        A = vcat(
            zeros(idx - 1),
            G / term,
            zeros(length(s_alias) - length(G) - (idx - 1)),
        )
        return A
    elseif context_key in keys(ctx.assets)
        # we model an FX rate or asset price
        @assert term == 0.0
        @assert isa(mdl, CompositeModel)
        #
        s_alias = state_alias(mdl)
        #
        asset_model_alias = ctx.assets[context_key].asset_model_alias
        @assert !isnothing(asset_model_alias) # handle this case later
        asset_model = mdl.models[mdl.model_dict[asset_model_alias]]
        @assert isa(asset_model, AssetModel)
        #
        dom_model_alias = ctx.assets[context_key].domestic_model_alias
        @assert !isnothing(dom_model_alias) # handle this case later
        dom_model = mdl.models[mdl.model_dict[dom_model_alias]]
        @assert isa(dom_model, SeparableHjmModel)
        #
        for_model_alias = ctx.assets[context_key].foreign_model_alias
        @assert !isnothing(for_model_alias) # handle this case later
        for_model = mdl.models[mdl.model_dict[for_model_alias]]
        @assert isa(for_model, SeparableHjmModel)
        #
        A = zeros(0)
        for m in mdl.models  # assume unique model alias
            if alias(m) == asset_model_alias
                A = vcat(A, [1.0])
            elseif alias(m) == dom_model_alias
                n = length(state_alias(dom_model))
                A = vcat(A, zeros(n-1), [1.0])
            elseif alias(m) == for_model_alias
                n = length(state_alias(for_model))
                A = vcat(A, zeros(n-1), [-1.0])
            else
                n = length(state_alias(m))
                A = vcat(A, zeros(n))
            end
        end
        return A
    else
        error("context_key " * context_key * " not found in Context.")
    end
end


"""
    reference_rate_scaling(
        keys_and_terms::AbstractVector,
        mdl::Model,
        ctx::Context
        )

Return the scaling matrix of a reference rates. The scaling matrix
represents a list of scaling vectors represented as matrix.

`keys_and_terms` is a list of tuples. For each tuple, the first
element represents the `context_key` of the reference rate. The
second element represents the `term` of the reference rate.
"""
function reference_rate_scaling(
    keys_and_terms::AbstractVector,
    mdl::Model,
    ctx::Context
    )
    # check reference rate spec
    for elm in keys_and_terms
        @assert length(elm) == 2
        @assert isa(elm[1], AbstractString)
        @assert isa(elm[2], Number)
    end
    A = hcat([
        reference_rate_scaling(elm[1], elm[2], mdl, ctx)
        for elm in keys_and_terms
    ]...)
    return A
end


"""
    reference_rate_covariance(
        Y1::AbstractVecOrMat,
        Y2::AbstractVecOrMat,
        mdl::Model,
        ch::CorrelationHolder,
        s::ModelTime,
        t::ModelTime,
        )

Calculate the covariance matrix for two vector or
matrices of reference rates.
"""
function reference_rate_covariance(
    Y1::AbstractVecOrMat,
    Y2::AbstractVecOrMat,
    mdl::Model,
    ch::CorrelationHolder,
    s::ModelTime,
    t::ModelTime,
    )
    #
    C = covariance(mdl, ch, s, t)
    return Y1' * C * Y2
end


"""
    reference_rate_covariance(
        Y1::Tuple,
        Y2::Tuple,
        mdl::Model,
        ch::CorrelationHolder,
        s::ModelTime,
        t::ModelTime,
        )

Calculate the scalar covariance for two reference rates.

Reference rates are encoded as tuples `Y1` and `Y2`.
The first element of a tuple is the `context_key`. The
second element of the tuple is the `term`.
"""
function reference_rate_covariance(
    R1::Tuple,
    R2::Tuple,
    ctx::Context,
    mdl::Model,
    ch::CorrelationHolder,
    s::ModelTime,
    t::ModelTime,
    )
    #
    Y1 = reference_rate_scaling(R1[1], R1[2], mdl, ctx)
    Y2 = reference_rate_scaling(R2[1], R2[2], mdl, ctx)
    return reference_rate_covariance(Y1, Y2, mdl, ch, s, t)
end


"""
    reference_rate_covariance(
        keys_and_terms::AbstractVector,
        ctx::Context,
        mdl::Model,
        ch::CorrelationHolder,
        s::ModelTime,
        t::ModelTime,
        )

Calculate covariance matrix for a list of reference rates.

`keys_and_terms` is a list of tuples. For each tuple, the first
element represents the `context_key` of the reference rate. The
second element represents the `term` of the reference rate.
"""
function reference_rate_covariance(
    keys_and_terms::AbstractVector,
    ctx::Context,
    mdl::Model,
    ch::CorrelationHolder,
    s::ModelTime,
    t::ModelTime,
    )
    #
    Y = reference_rate_scaling(keys_and_terms, mdl, ctx)
    return reference_rate_covariance(Y, Y, mdl, ch, s, t)
end


"""
    reference_rate_volatility_and_correlation(
        keys_and_terms::AbstractVector,
        ctx::Context,
        mdl::Model,
        ch::CorrelationHolder,
        s::ModelTime,
        t::ModelTime,
        )

Calculate the volatility vector and correlation matrix
for a list of reference rates.

`keys_and_terms` is a list of tuples. For each tuple, the first
element represents the `context_key` of the reference rate. The
second element represents the `term` of the reference rate.
"""
function reference_rate_volatility_and_correlation(
    keys_and_terms::AbstractVector,
    ctx::Context,
    mdl::Model,
    ch::CorrelationHolder,
    s::ModelTime,
    t::ModelTime,
    vol_eps::ModelValue = 1.0e-8,  # avoid division by zero
    )
    #
    d = length(keys_and_terms)
    cov = reference_rate_covariance(keys_and_terms, ctx, mdl, ch, s, t)
    vol = sqrt.([ cov[i,i] for i in 1:d ] .* (1.0/(t-s) ))
    #
    corr_(i,j) = begin
        if i<j
            return corr_(j,i) # ensure symmetry
        end
        if i==j
            return 1.0 + 0.0 * cov[i,j]  # ensure type-stability
        end
        # i > j
        if (vol[i]>vol_eps) && (vol[j]>vol_eps)
            return cov[i,j] / vol[i] / vol[j] / (t-s)
        end
        return 0.0 * cov[i,j]  # ensure type-stability
    end
    corr = [ corr_(i,j) for i in 1:d, j in 1:d ]
    return (vol, corr)
end
