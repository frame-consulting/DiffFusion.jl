# Simulated Paths

The concept of a path adds a layer of abstraction. On the one-hand side we have models and simulations. These objects are specified by the mathematical details of stochastic processes. On the other hand-side we have payoffs and products. These objects are specified by the business context.

A path is used to link business context and payoff evaluation to models and simulations.

## Path Creation

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

## Path Functions

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

## Auxiliary methods

```@docs
DiffFusion.length
```

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
