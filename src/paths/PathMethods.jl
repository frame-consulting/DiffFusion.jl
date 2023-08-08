
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
function numeraire(p::Path, t::ModelTime, curve_key::String)
    key = _split_key_identifyer * curve_key  # allow for context key parsing and ensure normalisation
    (context_key, ts_key_1, ts_key_2, op) = context_keys(key)
    entry = p.context.numeraire
    ts_alias_1 = entry.termstructure_dict[ts_key_1]
    df = discount(t, p.ts_dict, ts_alias_1)
    if isnothing(p.context.numeraire.model_alias)
        return (1.0/df) * ones(size(p.sim.X)[2]) 
    end
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    s = log_bank_account(p.sim.model, p.context.numeraire.model_alias, t, SX)
    return (1.0/df) * exp.(s)
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
        return (1.0/df) * ones(size(p.sim.X)[2]) 
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    s = log_bank_account(p.sim.model, entry.model_alias, t, SX)
    return (1.0/df) * exp.(s)
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
        return (df2/df1) * ones(size(p.sim.X)[2])
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    s = log_zero_bond(p.sim.model, entry.model_alias, t, T, SX)
    return (df2/df1) * exp.(-s)
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
        return (spot*df) * ones(size(p.sim.X)[2])
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    y = zeros(size(p.sim.X)[2])
    if !isnothing(entry.asset_model_alias)
        y += log_asset(p.sim.model, entry.asset_model_alias, t, SX)
    end
    if !isnothing(entry.domestic_model_alias)
        y += log_bank_account(p.sim.model, entry.domestic_model_alias, t, SX)
    end
    if !isnothing(entry.foreign_model_alias)
        y -= log_bank_account(p.sim.model, entry.foreign_model_alias, t, SX)
    end
    return (spot*df) * exp.(y)
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
        return (spot*df) * ones(size(p.sim.X)[2])
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    y = zeros(size(p.sim.X)[2])
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
    return (spot*df) * exp.(y)
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
    return fixing * ones(length(p))
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
        return forward_index * ones(size(p.sim.X)[2])
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    y = zeros(size(p.sim.X)[2])
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
    return forward_index * exp.(y)
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
        return future_index * ones(size(p.sim.X)[2])
    end
    #
    X = state_variable(p.sim, t, p.interpolation)
    SX = model_state(X, p.state_alias_dict)
    y = log_future(p.sim.model, entry.future_model_alias, t, T, SX)
    return future_index * exp.(y)
end

