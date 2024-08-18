
"""
Implement AbstractPath interface functions.

These methods implement the reconstruction of financial quantities from
modelled state variables and model functions.
"""


"""
    discount(
        t::ModelTime,
        ts_dict::Dict{String,Termstructure},
        first_alias::String,
        second_alias::Union{String,Nothing} = nothing,
        operation::Union{String,Nothing} = nothing,
        )

Derive the discount factor for one or two of curve alias and a curve operation.
"""
function discount(
    t::ModelTime,
    ts_dict::Dict{String,Termstructure},
    first_alias::String,
    second_alias::Union{String,Nothing} = nothing,
    operation::Union{String,Nothing} = nothing,
    )
    ts1 = ts_dict[first_alias]
    @assert isa(ts1, YieldTermstructure)
    df1 = discount(ts1, t)
    if !isnothing(second_alias)
        @assert operation in ("+", "-")
        ts2 = ts_dict[second_alias]
        @assert isa(ts2, YieldTermstructure)
        df2 = discount(ts2, t)
        if operation == "+"
            df1 *= df2
        end 
        if operation == "-"
            df1 /= df2
        end
    end
    return df1
end


"""
    numeraire(p::Path, t::ModelTime, curve_key::String)

Calculate the numeraire in the domestic currency.

We allow for curve-specific numeraire calculation e.g. to allow
for trade-specific discounting in AMC valuation.
"""
function numeraire(p::Path, t::ModelTime, key::String)
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    entry = p.context.numeraire
    @assert context_key == entry.context_key
    ts_alias_1 = entry.termstructure_dict[ts_key_1]
    if ts_key_2 == _empty_context_key || op == _empty_context_key
        # This is some business logic that overlaps with context_keys(...).
        # However, the logic is different e.g. for assets. So it makes
        # sense to leave it here.
        ts_alias_2 = nothing
    else
        ts_alias_2 = entry.termstructure_dict[ts_key_2]
    end
    df = discount(t, p.ts_dict, ts_alias_1, ts_alias_2, op)
    if isnothing(entry.model_alias)
        return (1.0/df) * ones(length(p)) 
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    s = log_bank_account(p.sim.model, entry.model_alias, t, SX)
    return (1.0/df) .* exp.(s)
end


"""
    bank_account(p::Path, t::ModelTime, key::String)

Calculate a continuous compounded bank account value.
"""
function bank_account(p::Path, t::ModelTime, key::String)
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    entry = p.context.rates[context_key]
    ts_alias_1 = entry.termstructure_dict[ts_key_1]
    if ts_key_2 == _empty_context_key || op == _empty_context_key
        # This is some business logic that overlaps with context_keys(...).
        # However, the logic is different e.g. for assets. So it makes
        # sense to leave it here.
        ts_alias_2 = nothing
    else
        ts_alias_2 = entry.termstructure_dict[ts_key_2]
    end
    df = discount(t, p.ts_dict, ts_alias_1, ts_alias_2, op)
    if isnothing(entry.model_alias)
        return (1.0/df) * ones(length(p)) 
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    s = log_bank_account(p.sim.model, entry.model_alias, t, SX)
    return (1.0/df) .* exp.(s)
end


"""
    zero_bond(p::Path, t::ModelTime, T::ModelTime, key::String)

Calculate a zero coupon bond price.
"""
function zero_bond(p::Path, t::ModelTime, T::ModelTime, key::String)
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    entry = p.context.rates[context_key]
    ts_alias_1 = entry.termstructure_dict[ts_key_1]
    if ts_key_2 == _empty_context_key || op == _empty_context_key
        # This is some business logic that overlaps with context_keys(...).
        # However, the logic is different e.g. for assets. So it makes
        # sense to leave it here.
        ts_alias_2 = nothing
    else
        ts_alias_2 = entry.termstructure_dict[ts_key_2]
    end
    df1 = discount(t, p.ts_dict, ts_alias_1, ts_alias_2, op)
    df2 = discount(T, p.ts_dict, ts_alias_1, ts_alias_2, op)
    if isnothing(entry.model_alias)
        return (df2/df1) .* ones(length(p))
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    s = log_zero_bond(p.sim.model, entry.model_alias, t, T, SX)
    return (df2/df1) .* exp.((-1.0) .* s)
end


"""
    zero_bonds(p::Path, t::ModelTime, T::AbstractVector, key::String)

Calculate zero coupon bond prices.
"""
function zero_bonds(p::Path, t::ModelTime, T::AbstractVector, key::String)
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    entry = p.context.rates[context_key]
    ts_alias_1 = entry.termstructure_dict[ts_key_1]
    if ts_key_2 == _empty_context_key || op == _empty_context_key
        # This is some business logic that overlaps with context_keys(...).
        # However, the logic is different e.g. for assets. So it makes
        # sense to leave it here.
        ts_alias_2 = nothing
    else
        ts_alias_2 = entry.termstructure_dict[ts_key_2]
    end
    df1 = discount(t, p.ts_dict, ts_alias_1, ts_alias_2, op)
    df2 = [ discount(T_, p.ts_dict, ts_alias_1, ts_alias_2, op) for T_ in T ]
    if isnothing(entry.model_alias)
        return (df2./df1)' .* ones(length(p))
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    s = log_zero_bonds(p.sim.model, entry.model_alias, t, T, SX)
    return (df2./df1)' .* exp.((-1.0) .* s)
end


"""
    compounding_factor(p::Path, t::ModelTime, T1::ModelTime, T2::ModelTime, key::String)

Calculate a compounding factor P(t,T1) / P(t,T2).
"""
function compounding_factor(p::Path, t::ModelTime, T1::ModelTime, T2::ModelTime, key::String)
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    entry = p.context.rates[context_key]
    ts_alias_1 = entry.termstructure_dict[ts_key_1]
    if ts_key_2 == _empty_context_key || op == _empty_context_key
        # This is some business logic that overlaps with context_keys(...).
        # However, the logic is different e.g. for assets. So it makes
        # sense to leave it here.
        ts_alias_2 = nothing
    else
        ts_alias_2 = entry.termstructure_dict[ts_key_2]
    end
    df1 = discount(T1, p.ts_dict, ts_alias_1, ts_alias_2, op)
    df2 = discount(T2, p.ts_dict, ts_alias_1, ts_alias_2, op)
    if isnothing(entry.model_alias)
        return (df1/df2) .* ones(length(p))
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    s = log_compounding_factor(p.sim.model, entry.model_alias, t, T1, T2, SX)
    return (df1/df2) .* exp.(s)
end


"""
    asset(p::Path, t::ModelTime, key::String)

Calculate asset price.
"""
function asset(p::Path, t::ModelTime, key::String)
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    @assert op in (_empty_context_key, "-")
    entry = p.context.assets[context_key]
    #
    spot_alias = entry.asset_spot_alias
    spot = p.ts_dict[spot_alias](t, TermstructureScalar)
    #
    ts_alias_1 = entry.foreign_termstructure_dict[ts_key_1]
    ts_alias_2 = entry.domestic_termstructure_dict[ts_key_2]
    df = discount(t, p.ts_dict, ts_alias_1, ts_alias_2, "-")  # double-check (de-)numerator
    #
    if isnothing(entry.asset_model_alias) &&
        isnothing(entry.foreign_model_alias) &&
        isnothing(entry.domestic_model_alias)
        # we can take a short-cut for fully deterministic models
        return (spot*df) .* ones(length(p))
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    # We add some short-cuts for typical model settings
    # FX model
    if !isnothing(entry.asset_model_alias) &&
        !isnothing(entry.domestic_model_alias) &&
        !isnothing(entry.foreign_model_alias)
        #
        return (spot*df) .* exp.(
            log_asset(p.sim.model, entry.asset_model_alias, t, SX) .+
            log_bank_account(p.sim.model, entry.domestic_model_alias, t, SX) .-
            log_bank_account(p.sim.model, entry.foreign_model_alias, t, SX)
        )
    end
    # Equity model
    if !isnothing(entry.asset_model_alias) &&
        !isnothing(entry.domestic_model_alias) &&
        isnothing(entry.foreign_model_alias)
        #
        return (spot*df) .* exp.(
            log_asset(p.sim.model, entry.asset_model_alias, t, SX) .+
            log_bank_account(p.sim.model, entry.domestic_model_alias, t, SX)
        )
    end
    # DK model
    if isnothing(entry.asset_model_alias) &&
        !isnothing(entry.domestic_model_alias) &&
        !isnothing(entry.foreign_model_alias)
        #
        return (spot*df) .* exp.(
            log_bank_account(p.sim.model, entry.domestic_model_alias, t, SX) .-
            log_bank_account(p.sim.model, entry.foreign_model_alias, t, SX)
        )
    end
    # all other cases are handled via default methodology
    y = zeros(length(p))
    if !isnothing(entry.asset_model_alias)
        y += log_asset(p.sim.model, entry.asset_model_alias, t, SX)
    end
    if !isnothing(entry.domestic_model_alias)
        y += log_bank_account(p.sim.model, entry.domestic_model_alias, t, SX)
    end
    if !isnothing(entry.foreign_model_alias)
        y -= log_bank_account(p.sim.model, entry.foreign_model_alias, t, SX)
    end
    return (spot*df) .* exp.(y)
end


"""
    forward_asset(p::Path, t::ModelTime, T::ModelTime, key::String)

Calculate forward asset price as expectation in T-forward measure, conditional on time-t.
"""
function forward_asset(p::Path, t::ModelTime, T::ModelTime, key::String)
    @assert t <= T
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    @assert op in (_empty_context_key, "-")
    entry = p.context.assets[context_key]
    #
    spot_alias = entry.asset_spot_alias
    spot = p.ts_dict[spot_alias](T, TermstructureScalar)  # capture any discrete jumps until T
    #
    ts_alias_1 = entry.foreign_termstructure_dict[ts_key_1]
    ts_alias_2 = entry.domestic_termstructure_dict[ts_key_2]
    df = discount(T, p.ts_dict, ts_alias_1, ts_alias_2, "-")  # capture continuous dividends/discounting until T
    #
    if isnothing(entry.asset_model_alias) &&
        isnothing(entry.foreign_model_alias) &&
        isnothing(entry.domestic_model_alias)
        # we can take a short-cut for fully deterministic models
        return (spot*df) .* ones(length(p))
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    # We add some short-cuts for typical model settings
    # FX model
    if !isnothing(entry.asset_model_alias) &&
        !isnothing(entry.domestic_model_alias) &&
        !isnothing(entry.foreign_model_alias)
        #
        return (spot*df) .* exp.(
            log_asset(p.sim.model, entry.asset_model_alias, t, SX) .+
            log_bank_account(p.sim.model, entry.domestic_model_alias, t, SX) .+
            log_zero_bond(p.sim.model, entry.domestic_model_alias, t, T, SX) .-
            log_bank_account(p.sim.model, entry.foreign_model_alias, t, SX) .-
            log_zero_bond(p.sim.model, entry.foreign_model_alias, t, T, SX)
        )
    end
    # Equity model
    if !isnothing(entry.asset_model_alias) &&
        !isnothing(entry.domestic_model_alias) &&
        isnothing(entry.foreign_model_alias)
        #
        return (spot*df) .* exp.(
            log_asset(p.sim.model, entry.asset_model_alias, t, SX) .+
            log_bank_account(p.sim.model, entry.domestic_model_alias, t, SX) .+
            log_zero_bond(p.sim.model, entry.domestic_model_alias, t, T, SX)
        )
    end
    # DK model
    if isnothing(entry.asset_model_alias) &&
        !isnothing(entry.domestic_model_alias) &&
        !isnothing(entry.foreign_model_alias)
        #
        return (spot*df) .* exp.(
            log_bank_account(p.sim.model, entry.domestic_model_alias, t, SX) .+
            log_zero_bond(p.sim.model, entry.domestic_model_alias, t, T, SX) .-
            log_bank_account(p.sim.model, entry.foreign_model_alias, t, SX) .-
            log_zero_bond(p.sim.model, entry.foreign_model_alias, t, T, SX)
        )
    end
    # all other cases are handled via default methodology
    y = zeros(length(p))
    if !isnothing(entry.asset_model_alias)
        y += log_asset(p.sim.model, entry.asset_model_alias, t, SX)
    end
    if !isnothing(entry.domestic_model_alias)
        y += log_bank_account(p.sim.model, entry.domestic_model_alias, t, SX)
        y += log_zero_bond(p.sim.model, entry.domestic_model_alias, t, T, SX)
    end
    if !isnothing(entry.foreign_model_alias)
        y -= log_bank_account(p.sim.model, entry.foreign_model_alias, t, SX)
        y -= log_zero_bond(p.sim.model, entry.foreign_model_alias, t, T, SX)
    end
    return (spot*df) .* exp.(y)
end



"""
    forward_asset_zero_bonds(p::Path, t::ModelTime, T::ModelTime, key::String)

Calculate asset (plus deterministic jumps) as well as domestic and foreign
zero bond price associated with an `Asset` key.

This function implements methodology redundant to `forward_asset(...)`. But it
returns asset and zero bonds separately.

This function is used for barrier option pricing.
"""
function forward_asset_and_zero_bonds(p::Path, t::ModelTime, T::ModelTime, key::String)
    @assert t <= T
    (context_key, ts_key_for, ts_key_dom, op) = context_keys(key)
    @assert op in (_empty_context_key, "-")
    entry = p.context.assets[context_key]
    #
    spot_alias = entry.asset_spot_alias
    spot = p.ts_dict[spot_alias](T, TermstructureScalar)  # capture any discrete jumps until T to be consistent with forward_asset
    #
    ts_alias_dom = entry.domestic_termstructure_dict[ts_key_dom]
    df_dom_t = discount(t, p.ts_dict, ts_alias_dom)
    df_dom_T = discount(T, p.ts_dict, ts_alias_dom)
    #
    ts_alias_for = entry.foreign_termstructure_dict[ts_key_for]
    df_for_t = discount(t, p.ts_dict, ts_alias_for)
    df_for_T = discount(T, p.ts_dict, ts_alias_for)
    #
    if isnothing(entry.asset_model_alias) &&
        isnothing(entry.foreign_model_alias) &&
        isnothing(entry.domestic_model_alias)
        # we can take a short-cut for fully deterministic models
        e = ones(length(p))
        return ((spot*df_for_t/df_dom_t) .*e, (df_dom_T/df_dom_t).*e, (df_for_T/df_for_t).*e)
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    #
    y_ast = zeros(length(p))
    y_dom = zeros(length(p))
    y_for = zeros(length(p))
    if !isnothing(entry.asset_model_alias)
        y_ast .+= log_asset(p.sim.model, entry.asset_model_alias, t, SX)
    end
    if !isnothing(entry.domestic_model_alias)
        y_ast .+= log_bank_account(p.sim.model, entry.domestic_model_alias, t, SX)
        y_dom .-= log_zero_bond(p.sim.model, entry.domestic_model_alias, t, T, SX)
    end
    if !isnothing(entry.foreign_model_alias)
        y_ast .-= log_bank_account(p.sim.model, entry.foreign_model_alias, t, SX)
        y_for .-= log_zero_bond(p.sim.model, entry.foreign_model_alias, t, T, SX)
    end
    asset = (spot * df_for_t / df_dom_t) .* exp.(y_ast)
    zb_dom = (df_dom_T / df_dom_t) .* exp.(y_dom)
    zb_for = (df_for_T / df_for_t) .* exp.(y_for)
    return (asset, zb_dom, zb_for)
end


"""
    fixing(p::Path, t::ModelTime, key::String)

Return a fixing from a term structure.
"""
function fixing(p::Path, t::ModelTime, key::String)
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    context_key = _join_context_keys(context_key, ts_key_1, ts_key_2, op)  # workaround
    entry = p.context.fixings[context_key]
    #
    ts_alias = entry.termstructure_alias
    fixing = p.ts_dict[ts_alias](t, TermstructureScalar)
    return fixing .* ones(length(p))
end



"""
    forward_index(p::Path, t::ModelTime, T::ModelTime, key::String)

Expectation E_t^T[S_T] of a tradeable asset.
"""
function forward_index(p::Path, t::ModelTime, T::ModelTime, key::String)
    @assert t <= T
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    @assert op in (_empty_context_key, "-")
    entry = p.context.forward_indices[context_key]
    #
    forward_index_alias = entry.forward_index_alias
    forward_index = p.ts_dict[forward_index_alias](T, TermstructureScalar)
    #
    if isnothing(entry.asset_model_alias) &&
        isnothing(entry.foreign_model_alias) &&
        isnothing(entry.domestic_model_alias)
        # we can take a short-cut for fully deterministic models
        return forward_index * ones(length(p))
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    y = zeros(length(p))
    if !isnothing(entry.asset_model_alias)
        y += log_asset(p.sim.model, entry.asset_model_alias, t, SX)
    end
    if !isnothing(entry.domestic_model_alias)
        y += log_bank_account(p.sim.model, entry.domestic_model_alias, t, SX)
        if t < T
            y += log_zero_bond(p.sim.model, entry.domestic_model_alias, t, T, SX)
        end
    end
    if !isnothing(entry.foreign_model_alias)
        y -= log_bank_account(p.sim.model, entry.foreign_model_alias, t, SX)
        if t < T
            y -= log_zero_bond(p.sim.model, entry.foreign_model_alias, t, T, SX)
        end
    end
    return forward_index .* exp.(y)
end


"""
    future_index(p::Path, t::ModelTime, T::ModelTime, key::String)

Expectation E_t^Q[F(T,T)] of a Future index/price.
"""
function future_index(p::Path, t::ModelTime, T::ModelTime, key::String)
    @assert t <= T
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    @assert op in (_empty_context_key, "-")
    entry = p.context.future_indices[context_key]
    #
    future_index_alias = entry.future_index_alias
    future_index = p.ts_dict[future_index_alias](T, TermstructureScalar)
    #
    if isnothing(entry.future_model_alias)
        # we can take a short-cut for fully deterministic models
        return future_index * ones(length(p))
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    y = log_future(p.sim.model, entry.future_model_alias, t, T, SX)
    return future_index .* exp.(y)
end


"""
    swap_rate_variance(
        p::Path,
        t::ModelTime,
        T::ModelTime,
        swap_times::AbstractVector,
        yf_weights::AbstractVector,
        key::String,
        )

Calculate the normal model variance of a swap rate via Gaussian
swap rate approximation.
"""
function swap_rate_variance(
    p::Path,
    t::ModelTime,
    T::ModelTime,
    swap_times::AbstractVector,
    yf_weights::AbstractVector,
    key::String,
    )
    #
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    entry = p.context.rates[context_key]
    ts_alias_1 = entry.termstructure_dict[ts_key_1]
    @assert op in (_empty_context_key,)  # we just want a single discount curve
    #
    if isnothing(entry.model_alias)
        return zeros(length(p))  # deterministic model
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    return swap_rate_variance(
        p.sim.model,
        entry.model_alias,
        p.ts_dict[ts_alias_1],
        t,
        T,
        swap_times,
        yf_weights,
        SX,
    )
end


"""
    forward_rate_variance(
    p::Path,
    t::ModelTime,
    T::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    key::String,
    )

Calculate the lognormal variance for a compounding factor of a forward-looking
or backward-looking forward rate.

"""
function forward_rate_variance(
    p::Path,
    t::ModelTime,
    T::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    key::String,
    )
    #
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    entry = p.context.rates[context_key]
    #
    if isnothing(entry.model_alias)
        return zeros(length(p))  # deterministic model
    end
    #
    return ones(length(p)) .* forward_rate_variance(
        p.sim.model,
        entry.model_alias,
        t,
        T,
        T0,
        T1,
    )
end


"""
    asset_variance(
        p::Path,
        t::ModelTime,
        T::ModelTime,
        key::String,
        )

Calculate the lognormal model variance of an asset spot price
over the time period [t,T].
"""
function asset_variance(
    p::Path,
    t::ModelTime,
    T::ModelTime,
    key::String,
    )
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    @assert op in (_empty_context_key, "-")
    entry = p.context.assets[context_key]
    #
    if isnothing(entry.asset_model_alias) &&
        isnothing(entry.domestic_model_alias) &&
        isnothing(entry.foreign_model_alias)
        return zeros(length(p))  # deterministic model
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    #
    return ones(length(p)) .* asset_variance(
        p.sim.model,
        entry.asset_model_alias,
        entry.domestic_model_alias,
        entry.foreign_model_alias,
        t,
        T,
        SX,
    )
end


"""
    asset_convexity_adjustment(
        p::Path,
        t::ModelTime,
        T0::ModelTime,
        T1::ModelTime,
        T2::ModelTime,
        key::String
        )

Return the convexity adjustment for a YoY asset payoff.
"""
function asset_convexity_adjustment(
    p::Path,
    t::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    T2::ModelTime,
    key::String
    )
    #
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    @assert op in (_empty_context_key, "-")
    entry = p.context.assets[context_key]
    #
    @assert t  <= T0
    @assert T0 <= T1
    @assert T1 <= T2
    # TODO: specialise for deterministic models
    @assert !isnothing(entry.domestic_model_alias)
    @assert !isnothing(entry.foreign_model_alias)
    @assert !isnothing(entry.asset_model_alias)
    #
    ca = log_asset_convexity_adjustment(
        p.sim.model,
        entry.domestic_model_alias,
        entry.foreign_model_alias,
        entry.asset_model_alias,
        t,
        T0,
        T1,
        T2,
    )
    return exp(ca) * ones(length(p))
end


"""
    index_convexity_adjustment(
        p::Path,
        t::ModelTime,
        T0::ModelTime,
        T1::ModelTime,
        T2::ModelTime,
        key::String
        )

Return the convexity adjustment for a YoY index payoff.
"""
function index_convexity_adjustment(
    p::Path,
    t::ModelTime,
    T0::ModelTime,
    T1::ModelTime,
    T2::ModelTime,
    key::String
    )
    #
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    @assert op in (_empty_context_key,)
    entry = p.context.forward_indices[context_key]
    #
    @assert t  <= T0
    @assert T0 <= T1
    @assert T1 <= T2
    # TODO: specialise for deterministic models
    @assert !isnothing(entry.domestic_model_alias)
    @assert !isnothing(entry.foreign_model_alias)
    @assert !isnothing(entry.asset_model_alias)
    #
    ca = log_asset_convexity_adjustment(
        p.sim.model,
        entry.domestic_model_alias,
        entry.foreign_model_alias,
        entry.asset_model_alias,
        t,
        T0,
        T1,
        T2,
    )
    return exp(ca) * ones(length(p))
end
