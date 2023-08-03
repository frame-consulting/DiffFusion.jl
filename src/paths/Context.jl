

"""
    abstract type ContextEntry end

A `ContextEntry` represents a mapping from a context key to model aliases
and term structure aliases.

We use the convention that keys are UPPERCASE strings. This aims at
helping to distinguish between keys and alias.
"""
abstract type ContextEntry end

"""
    key(ce::ContextEntry)

Return the context key of a context entry.
"""
function key(ce::ContextEntry)
    return ce.context_key
end


"""
    struct NumeraireEntry <: ContextEntry
        context_key::String
        model_alias::Union{String, Nothing}
        termstructure_dict::Dict{String,String}
    end

A `NumeraireEntry` represents a link to an interest rate model and
yield curves used for numeraire calculation.

We opt to allow for different yield curves in numeraire application.
This should allow e.g. AMC methods wih trade-specific discounting.

An empty model alias (`nothing`) represents a deterministic model.

The `termstructure_dict` maps term structure keys to term structure
aliases.

We use the convention that keys are UPPERCASE strings. This aims at
helping to distinguish between keys and alias.
"""
struct NumeraireEntry <: ContextEntry
    context_key::String
    model_alias::Union{String, Nothing}
    termstructure_dict::Dict{String,String}
end


"""
    struct RatesEntry <: ContextEntry
        context_key::String
        model_alias::Union{String, Nothing}
        termstructure_dict::Dict{String,String}
    end

A `RatesEntry` represents a link to an interest rate model and
yield curves used for zero coupon bond calculation.

An empty model alias (`nothing`) represents a deterministic model.

The `termstructure_dict` maps term structure keys to term structure
aliases.

We use the convention that keys are UPPERCASE strings. This aims at
helping to distinguish between keys and alias.
"""
struct RatesEntry <: ContextEntry
    context_key::String
    model_alias::Union{String, Nothing}
    termstructure_dict::Dict{String,String}
end


"""
    struct AssetEntry <: ContextEntry
        context_key::String
        asset_model_alias::Union{String, Nothing}
        domestic_model_alias::Union{String, Nothing}
        foreign_model_alias::Union{String, Nothing}
        asset_spot_alias::String
        domestic_termstructure_dict::Dict{String,String}
        foreign_termstructure_dict::Dict{String,String}
    end

An `AssetEntry` represents a link to an asset model, two interest rate
models and yield curves. This entry is used to calculate future
simulated asset values.

We use the foreign currency analogy to represent tradeable assets.

An empty model alias (`nothing`) represents a deterministic model.

`domestic_termstructure_dict` and `foreign_termstructure_dict` map term
structure keys to term structure aliases.

We use the convention that keys are UPPERCASE strings. This aims at
helping to distinguish between keys and alias.
"""
struct AssetEntry <: ContextEntry
    context_key::String
    asset_model_alias::Union{String, Nothing}
    domestic_model_alias::Union{String, Nothing}
    foreign_model_alias::Union{String, Nothing}
    asset_spot_alias::String
    domestic_termstructure_dict::Dict{String,String}
    foreign_termstructure_dict::Dict{String,String}
end


"""
    struct ForwardIndexEntry <: ContextEntry
        context_key::String
        asset_model_alias::Union{String, Nothing}
        domestic_model_alias::Union{String, Nothing}
        foreign_model_alias::Union{String, Nothing}
        forward_index_alias::String
    end

A `ForwardIndexEntry` represents a link to an asset model, two interest rate
models and a forward index curves. This entry is used to calculate future
simulated forward asset prices.

We use the foreign currency analogy to represent tradeable assets.

An empty model alias (`nothing`) represents a deterministic model.

`forward_index_alias` represents the link to the forward index curve.

We use the convention that keys are UPPERCASE strings. This aims at
helping to distinguish between keys and alias.
"""
struct ForwardIndexEntry <: ContextEntry
    context_key::String
    asset_model_alias::Union{String, Nothing}
    domestic_model_alias::Union{String, Nothing}
    foreign_model_alias::Union{String, Nothing}
    forward_index_alias::String
end


"""
    struct FutureIndexEntry <: ContextEntry
        context_key::String
        future_model_alias::Union{String, Nothing}
        future_index_alias::String
    end

A `FutureIndexEntry` represents a link to a Futures model and a future index curve.
This entry is used to calculate future simulated Future prices.

Key proposition is that the Future price is a martingale in the corresponding
domestic risk-neutral measure.

An empty model alias (`nothing`) represents a deterministic model.

`future_index_alias` represents the link to the Future index curve.

We use the convention that keys are UPPERCASE strings. This aims at
helping to distinguish between keys and alias.
"""
struct FutureIndexEntry <: ContextEntry
    context_key::String
    future_model_alias::Union{String, Nothing}
    future_index_alias::String
end


"""
    struct FixingEntry <: ContextEntry
        context_key::String
        termstructure_alias::String
    end

A `FixingEntry` represents a link to a parameter term structure
used to obtain fixings for indices etc.
"""
struct FixingEntry <: ContextEntry
    context_key::String
    termstructure_alias::String
end


"""
    struct Context
        alias::String
        numeraire::NumeraireEntry
        rates::Dict{String, RatesEntry}
        assets::Dict{String, AssetEntry}
        forward_indices::Dict{String, ForwardIndexEntry}
        future_indices::Dict{String, FutureIndexEntry}
        fixings::Dict{String, FixingEntry}
    end

A Context represents a mapping from market references (keys) to model
and term structure references (aliases).

Links are represented as key/alias pairs. market references are used
in the specification of payoffs and products. Model and term structure
references are used to set up models and model parameters.

In simple settings there can be a one-to-one mapping between market
references and model/term structure references. However, more realistic
settings benefit from an additional mapping. For example, discount
factors for two (or more) market reference (say EUR ESTR and EUR Euribor) 
can be calculated from a single model (with model reference EUR) and two
(or more) yield curves (with term structure reference ESTR and Euribor).

A Context

  - adds a layer of abstraction to disentangle models and products and

  - links models and term structures according to business logic.

"""
struct Context
    alias::String
    numeraire::NumeraireEntry
    rates::Dict{String, RatesEntry}
    assets::Dict{String, AssetEntry}
    forward_indices::Dict{String, ForwardIndexEntry}
    future_indices::Dict{String, FutureIndexEntry}
    fixings::Dict{String, FixingEntry}
end

"""
    alias(c::Context)

Return the alias of a Context object.
"""
function alias(c::Context)
    return c.alias
end


"""
    numeraire_entry(
        context_key::String,
        model_alias::Union{String, Nothing} = nothing,
        termstructure_dict::Union{AbstractDict, Nothing} = nothing,
        )

Simplify `NumeraireEntry` setup.
"""
function numeraire_entry(
    context_key::String,
    model_alias::Union{String, Nothing} = nothing,
    termstructure_dict::Union{AbstractDict, Nothing} = nothing,
    )
    #
    if isnothing(termstructure_dict)
        ts_dict = Dict(((_empty_context_key, context_key),))
    else
        ts_dict = Dict( (key, termstructure_dict[key]) for key in keys(termstructure_dict) )
    end
    return NumeraireEntry(context_key, model_alias, ts_dict)
end

"""
    numeraire_entry(
        context_key::String,
        model_alias::Union{String, Nothing},
        termstructure_alias::String,
        )

Simplify `NumeraireEntry` setup.
"""
function numeraire_entry(
    context_key::String,
    model_alias::Union{String, Nothing},
    termstructure_alias::String,
    )
    #
    ts_dict = Dict(((_empty_context_key, termstructure_alias),))
    return numeraire_entry(context_key, model_alias, ts_dict)
end


"""
    rates_entry(
        context_key::String,
        model_alias::Union{String, Nothing} = nothing,
        termstructure_dict::Union{AbstractDict, Nothing} = nothing,
        )

Simplify `RatesEntry` setup.
"""
function rates_entry(
    context_key::String,
    model_alias::Union{String, Nothing} = nothing,
    termstructure_dict::Union{AbstractDict, Nothing} = nothing,
    )
    #
    if isnothing(termstructure_dict)
        ts_dict = Dict(((_empty_context_key, context_key),))
    else
        ts_dict = Dict( (key, termstructure_dict[key]) for key in keys(termstructure_dict) )
    end
    return RatesEntry(context_key, model_alias, ts_dict)
end


"""
rates_entry(
        context_key::String,
        model_alias::Union{String, Nothing},
        termstructure_alias::String,
        )

Simplify `RatesEntry` setup.
"""
function rates_entry(
    context_key::String,
    model_alias::Union{String, Nothing},
    termstructure_alias::String,
    )
    #
    ts_dict = Dict(((_empty_context_key, termstructure_alias),))
    return rates_entry(context_key, model_alias, ts_dict)
end


"""
    asset_entry(
        context_key::String,
        asset_model_alias::Union{String, Nothing} = nothing,
        domestic_model_alias::Union{String, Nothing} = nothing,
        foreign_model_alias::Union{String, Nothing} = nothing,
        asset_spot_alias::Union{String, Nothing} = nothing,
        domestic_termstructure_dict::Union{AbstractDict, Nothing} = nothing,
        foreign_termstructure_dict::Union{AbstractDict, Nothing} = nothing,
        )

Simplify `AssetEntry` setup.
"""
function asset_entry(
    context_key::String,
    asset_model_alias::Union{String, Nothing} = nothing,
    domestic_model_alias::Union{String, Nothing} = nothing,
    foreign_model_alias::Union{String, Nothing} = nothing,
    asset_spot_alias::Union{String, Nothing} = nothing,
    domestic_termstructure_dict::Union{AbstractDict, Nothing} = nothing,
    foreign_termstructure_dict::Union{AbstractDict, Nothing} = nothing,
    )
    #
    if isnothing(asset_spot_alias)
        asset_spot_alias = context_key
    end
    if  isnothing(domestic_termstructure_dict) ||
        isnothing(foreign_termstructure_dict)
        for_dom_split = findfirst('-', context_key)  # assume FOR-DOM notation
        @assert !isnothing(for_dom_split)
    end
    if isnothing(domestic_termstructure_dict)
        dom_ts_dict = Dict(((_empty_context_key, context_key[for_dom_split+1:end]),))
    else
        dom_ts_dict = Dict( (key, domestic_termstructure_dict[key]) for key in keys(domestic_termstructure_dict) )
    end
    if isnothing(foreign_termstructure_dict)
        for_ts_dict = Dict(((_empty_context_key, context_key[begin:for_dom_split-1]),))
    else
        for_ts_dict = Dict( (key, foreign_termstructure_dict[key]) for key in keys(foreign_termstructure_dict) )
    end
    return AssetEntry(
        context_key,
        asset_model_alias,
        domestic_model_alias,
        foreign_model_alias,
        asset_spot_alias,
        dom_ts_dict,
        for_ts_dict,
        )
end


"""
    asset_entry(
        context_key::String,
        asset_model_alias::Union{String, Nothing} = nothing,
        domestic_model_alias::Union{String, Nothing} = nothing,
        foreign_model_alias::Union{String, Nothing} = nothing,
        asset_spot_alias::Union{String, Nothing} = nothing,
        domestic_termstructure_alias::String,
        foreign_termstructure_alias::String,
        )

Simplify `AssetEntry` setup.
"""
function asset_entry(
    context_key::String,
    asset_model_alias::Union{String, Nothing},
    domestic_model_alias::Union{String, Nothing},
    foreign_model_alias::Union{String, Nothing},
    asset_spot_alias::Union{String, Nothing},
    domestic_termstructure_alias::String,
    foreign_termstructure_alias::String,
    )
    #
    dom_ts_dict = Dict(((_empty_context_key, domestic_termstructure_alias),))
    for_ts_dict = Dict(((_empty_context_key, foreign_termstructure_alias ),))
    return asset_entry(
        context_key,
        asset_model_alias,
        domestic_model_alias,
        foreign_model_alias,
        asset_spot_alias,
        dom_ts_dict,
        for_ts_dict,
    )
end


"""
    forward_index_entry(
        context_key::String,
        asset_model_alias::Union{String, Nothing} = nothing,
        domestic_model_alias::Union{String, Nothing} = nothing,
        foreign_model_alias::Union{String, Nothing} = nothing,
        forward_index_alias::Union{String, Nothing} = nothing,
        )

Simplify `ForwardIndexEntry` setup.
"""
function forward_index_entry(
    context_key::String,
    asset_model_alias::Union{String, Nothing} = nothing,
    domestic_model_alias::Union{String, Nothing} = nothing,
    foreign_model_alias::Union{String, Nothing} = nothing,
    forward_index_alias::Union{String, Nothing} = nothing,
    )
    #
    if isnothing(forward_index_alias)
        forward_index_alias = context_key
    end
    return ForwardIndexEntry(
        context_key,
        asset_model_alias,
        domestic_model_alias,
        foreign_model_alias,
        forward_index_alias,
    )
end

"""
    future_index_entry(
        context_key::String,
        future_model_alias::Union{String, Nothing} = nothing,
        future_index_alias::String = nothing,
        )

Simplify `FutureIndexEntry` setup.
"""
function future_index_entry(
    context_key::String,
    future_model_alias::Union{String, Nothing} = nothing,
    future_index_alias::Union{String, Nothing} = nothing,
    )
    #
    if isnothing(future_index_alias)
        future_index_alias = context_key
    end
    return FutureIndexEntry(
        context_key,
        future_model_alias,
        future_index_alias,
    )
end


"""
    fixing_entry(
        context_key::String,
        termstructure_alias::Union{String, Nothing} = nothing,
        )

Simplify `FixingEntry` setup.
"""
function fixing_entry(
    context_key::String,
    termstructure_alias::Union{String, Nothing} = nothing,
    )
    #
    if isnothing(termstructure_alias)
        termstructure_alias = context_key
    end
    return FixingEntry(context_key, termstructure_alias)
end


"""
    context(
        alias::String,
        num_entry::NumeraireEntry,
        rates_entries::Union{AbstractVector, Nothing} = nothing,
        asset_entries::Union{AbstractVector, Nothing} = nothing,
        forward_index_entries::Union{AbstractVector, Nothing} = nothing,
        future_index_entries::Union{AbstractVector, Nothing} = nothing,
        fixing_entries::Union{AbstractVector, Nothing} = nothing,
        )

Simplify `Context` setup.
"""
function context(
    alias::String,
    num_entry::NumeraireEntry,
    rates_entries::Union{AbstractVector, Nothing} = nothing,
    asset_entries::Union{AbstractVector, Nothing} = nothing,
    forward_index_entries::Union{AbstractVector, Nothing} = nothing,
    future_index_entries::Union{AbstractVector, Nothing} = nothing,
    fixing_entries::Union{AbstractVector, Nothing} = nothing,
    )
    #
    if isnothing(rates_entries)
        rates = Dict{String, RatesEntry}()
    else
        rates = Dict{String, RatesEntry}(((e.context_key, e) for e in rates_entries))
    end
    if isnothing(asset_entries)
        assets = Dict{String, AssetEntry}()
    else
        assets = Dict{String, AssetEntry}(((e.context_key, e) for e in asset_entries))
    end
    if isnothing(forward_index_entries)
        forward_indices = Dict{String, ForwardIndexEntry}()
    else
        forward_indices = Dict{String, ForwardIndexEntry}(((e.context_key, e) for e in forward_index_entries))
    end
    if isnothing(future_index_entries)
        future_indices = Dict{String, FutureIndexEntry}()
    else
        future_indices = Dict{String, FutureIndexEntry}(((e.context_key, e) for e in future_index_entries))
    end
    if isnothing(fixing_entries)
        fixings = Dict{String, FixingEntry}()
    else
        fixings = Dict{String, FixingEntry}(((e.context_key, e) for e in fixing_entries))
    end
    return Context(
        alias,
        num_entry,
        rates,
        assets,
        forward_indices,
        future_indices,
        fixings,
        )
end



"""
    simple_context(alias::String, alias_list::AbstractVector)

Generate a simple Context based on a list of currency aliases.

User must ensure that aliases can be referenced as normalised keys.
"""
function simple_context(alias::String, alias_list::AbstractVector)
    @assert length(alias_list) > 0
    dom_alias = alias_list[1]
    numeraire = numeraire_entry(dom_alias, dom_alias)
    rates = [ rates_entry(a, a) for a in alias_list ]
    assets = [
        asset_entry(
            for_alias*"-"*dom_alias,
            for_alias*"-"*dom_alias,
            dom_alias,
            for_alias,
        )
        for for_alias in alias_list[2:end]
    ]
    forward_indices = ForwardIndexEntry[]
    future_indices = FutureIndexEntry[]
    fixings = FixingEntry[]
    return Context(alias,
        numeraire,
        Dict{String, RatesEntry}([(e.context_key, e) for e in rates]),
        Dict{String, AssetEntry}([(e.context_key, e) for e in assets]),
        Dict{String, ForwardIndexEntry}([(e.context_key, e) for e in forward_indices]),
        Dict{String, FutureIndexEntry}([(e.context_key, e) for e in future_indices]),
        Dict{String, FixingEntry}([(e.context_key, e) for e in fixings]),
    )
end


"""
    deterministic_model_context(alias::String, alias_list::AbstractVector)

Generate a simple Context for fully deterministic modelling based on a list
of currency aliases.

User must ensure that aliases can be referenced as normalised keys.
"""
function deterministic_model_context(alias::String, alias_list::AbstractVector)
    @assert length(alias_list) > 0
    dom_alias = alias_list[1]
    numeraire = numeraire_entry(dom_alias)
    rates = [ rates_entry(a) for a in alias_list ]
    assets = [
        asset_entry(
            for_alias*"-"*dom_alias,
            )
        for for_alias in alias_list[2:end]
    ]
    forward_indices = ForwardIndexEntry[]
    future_indices = FutureIndexEntry[]
    fixings = FixingEntry[]
    return Context(alias,
        numeraire,
        Dict{String, RatesEntry}([(e.context_key, e) for e in rates]),
        Dict{String, AssetEntry}([(e.context_key, e) for e in assets]),
        Dict{String, ForwardIndexEntry}([(e.context_key, e) for e in forward_indices]),
        Dict{String, FutureIndexEntry}([(e.context_key, e) for e in future_indices]),
        Dict{String, FixingEntry}([(e.context_key, e) for e in fixings]),
    )
end


"""
    context_keys(key::String)

Parse the context entry key and term structure keys from an
input key string.

We implement a simple syntax for input key strings:

    context_key:[ts_key_1][-,+][ts_key_2]

Result is a tuple of the form

    (context_key, ts_key_1, ts_key_2, [-,+])

Elements that are not found are returned as empty_context_key value.

We apply normalisation of keys to mitigate risk of key errors
by the user.
"""
function context_keys(key::String)
    first = split(key, _split_key_identifyer, limit=2)
    @assert length(first) > 0
    if length(first) == 1
        return (
            _normalise_context_keys(first[1]),
            _empty_context_key,
            _empty_context_key,
            _empty_context_key,
            )
    end
    second = split(first[2], "-", limit=2)
    if length(second) == 2
        return (
            _normalise_context_keys(first[1]),
            _normalise_context_keys(second[1]),
            _normalise_context_keys(second[2]),
            "-",
            )
    end
    second = split(first[2], "+", limit=2)
    if length(second) == 2
        return (
            _normalise_context_keys(first[1]),
            _normalise_context_keys(second[1]),
            _normalise_context_keys(second[2]),
            "+",
            )
    end
    return (
        _normalise_context_keys(first[1]),
        _normalise_context_keys(first[2]),
        _empty_context_key,
        _empty_context_key,
        )
end

"""
    _join_context_keys(key1, key2, key3, key4)

For fixings we want to re-join the key components
"""
function _join_context_keys(key1, key2, key3, key4)
    key = key1
    if key2 != _empty_context_key
        key = key * _split_key_identifyer * key2
    end
    if key4 != _empty_context_key
        key = key * key4 * key3
    end
    return key
end


"""
We specify how to split a key string.
"""
const _split_key_identifyer = ":"

"""
We specify a default value for context and curve keys.
    
This is deemed necessary because YAML serialisation cannot work with
empty string keys in dictionaries.
"""
const _empty_context_key = "<empty_key>"

"""
    _normalise_context_keys(key::AbstractString)

We specify a normalisation of context and curve keys.
"""
function _normalise_context_keys(key::AbstractString)
    # For now, we want to enforce normalises keys rather to adjust keys internally.
    @assert key == uppercase(key)
    if key == "" # We do not want empty strings as keys.
        return _empty_context_key
    end
    return key
end
