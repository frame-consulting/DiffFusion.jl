# Payoffs

In this section we document the payoff scripting framework.

```@docs
DiffFusion.Payoff
```

```@docs
DiffFusion.obs_time(p::DiffFusion.Payoff)
```

```@docs
DiffFusion.obs_times(p::DiffFusion.Payoff)
```

```@docs
DiffFusion.at(p::DiffFusion.Payoff, path::DiffFusion.AbstractPath)
```

## Leafs

```@docs
DiffFusion.Leaf
```

```@docs
DiffFusion.Numeraire
```

```@docs
DiffFusion.BankAccount
```

```@docs
DiffFusion.ZeroBond
```

```@docs
DiffFusion.Asset
```

```@docs
DiffFusion.ForwardAsset
```

```@docs
DiffFusion.Fixing
```

```@docs
DiffFusion.Fixed
```

## Unary Nodes

```@docs
DiffFusion.UnaryNode
```

```@docs
DiffFusion.Pay
```

```@docs
DiffFusion.Cache
```

## Binary Nodes

```@docs
DiffFusion.BinaryNode
```

```@docs
DiffFusion.Add
```

```@docs
DiffFusion.Sub
```

```@docs
DiffFusion.Mul
```

```@docs
DiffFusion.Div
```

```@docs
DiffFusion.Max
```

```@docs
DiffFusion.Min
```

```@docs
DiffFusion.Logical
```

## Rates Payoffs

```@docs
DiffFusion.LiborRate
```

```@docs
DiffFusion.LiborRate(
    obs_time::ModelTime,
    start_time::ModelTime,
    end_time::ModelTime,
    key::String,
    )
```

```@docs
DiffFusion.CompoundedRate
```

```@docs
DiffFusion.CompoundedRate(
    obs_time::ModelTime,
    start_time::ModelTime,
    end_time::ModelTime,
    key::String,
    )
```

## Common Methods Overview

```@docs
DiffFusion.obs_time
```

```@docs
DiffFusion.obs_times
```

```@docs
DiffFusion.at
```

```@docs
DiffFusion.string
```
