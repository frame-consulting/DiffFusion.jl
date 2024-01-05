# Monte Carlo Paths Functions

In this section we document data structures and methods for path setup.

## Simulation Context

```@docs
DiffFusion.Context
```

```@docs
DiffFusion.ContextEntry
```

```@docs
DiffFusion.NumeraireEntry
```

```@docs
DiffFusion.numeraire_entry
```

```@docs
DiffFusion.RatesEntry
```

```@docs
DiffFusion.rates_entry
```

```@docs
DiffFusion.AssetEntry
```

```@docs
DiffFusion.asset_entry
```

```@docs
DiffFusion.ForwardIndexEntry
```

```@docs
DiffFusion.forward_index_entry
```

```@docs
DiffFusion.FutureIndexEntry
```

```@docs
DiffFusion.future_index_entry
```

```@docs
DiffFusion.FixingEntry
```

```@docs
DiffFusion.fixing_entry
```

```@docs
DiffFusion.key(ce::DiffFusion.ContextEntry)
```

```@docs
DiffFusion.context
```

```@docs
DiffFusion.simple_context
```

```@docs
DiffFusion.deterministic_model_context
```

```@docs
DiffFusion.context_keys
```

## Simulated Paths

The concept of a path adds a layer of abstraction. On the one-hand side we have models and simulations. These objects are specified by the mathematical details of stochastic processes. On the other hand-side we have payoffs and products. These objects are specified by the business context.

A path is used to link business context and payoff evaluation to models and simulations.


```@docs
DiffFusion.AbstractPath
```

```@docs
DiffFusion.Path
```

```@docs
DiffFusion.path
```

```@docs
DiffFusion.PathInterpolation
```

```@docs
DiffFusion.length
```

```@docs
DiffFusion.numeraire
```

```@docs
DiffFusion.bank_account
```

```@docs
DiffFusion.zero_bond
```

```@docs
DiffFusion.zero_bonds
```

```@docs
DiffFusion.compounding_factor
```

```@docs
DiffFusion.asset
```

```@docs
DiffFusion.forward_asset
```

```@docs
DiffFusion.fixing
```

```@docs
DiffFusion.asset_convexity_adjustment
```

```@docs
DiffFusion.forward_index
```

```@docs
DiffFusion.index_convexity_adjustment
```

```@docs
DiffFusion.future_index
```

Auxiliary methods:

```@docs
DiffFusion.state_variable
```

```@docs
DiffFusion.discount(
    t::ModelTime,
    ts_dict::Dict{String,DiffFusion.Termstructure},
    first_alias::String,
    second_alias::Union{String,Nothing} = nothing,
    operation::Union{String,Nothing} = nothing,
    )
```
