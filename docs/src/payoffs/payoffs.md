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

```@docs
DiffFusion.Optionlet
```

```@docs
DiffFusion.Optionlet(
    obs_time_::ModelTime,
    expiry_time::ModelTime,
    forward_rate::Union{DiffFusion.LiborRate, DiffFusion.CompoundedRate},
    strike_rate::DiffFusion.Payoff,
    call_put::ModelValue,
    gearing_factor::DiffFusion.Payoff = DiffFusion.Fixed(1.0),
    )
```

```@docs
DiffFusion.Swaption
```

```@docs
DiffFusion.Swaption(
    obs_time_::ModelTime,
    expiry_time::ModelTime,
    settlement_time::ModelTime,
    forward_rates::AbstractVector,
    fixed_times::AbstractVector,
    fixed_weights::AbstractVector,
    fixed_rate::ModelValue,
    payer_receiver::ModelValue,
    disc_key::String,
    )
```



## American Monte Carlo Payoffs

```@docs
DiffFusion.AmcPayoff
```

```@docs
DiffFusion.AmcPayoffLinks
```

```@docs
DiffFusion.AmcPayoffRegression
```

```@docs
DiffFusion.AmcMax
```

```@docs
DiffFusion.AmcMax(
    obs_time::ModelTime,
    x::AbstractVector,
    y::AbstractVector,
    z::AbstractVector,
    path::Union{DiffFusion.AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
    curve_key::String,
    )
```

```@docs
DiffFusion.AmcMin
```

```@docs
DiffFusion.AmcMin(
    obs_time::ModelTime,
    x::AbstractVector,
    y::AbstractVector,
    z::AbstractVector,
    path::Union{DiffFusion.AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
    curve_key::String,
    )
```

```@docs
DiffFusion.AmcOne
```

```@docs
DiffFusion.AmcOne(
    obs_time::ModelTime,
    x::AbstractVector,
    y::AbstractVector,
    z::AbstractVector,
    path::Union{DiffFusion.AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
    curve_key::String,
    )
```

```@docs
DiffFusion.AmcSum
```

```@docs
DiffFusion.AmcSum(
    obs_time::ModelTime,
    x::AbstractVector,
    z::AbstractVector,
    path::Union{DiffFusion.AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
    curve_key::String,
    )
```

```@docs
DiffFusion.reset_regression!
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

```@docs
DiffFusion.calibrate_regression
```
