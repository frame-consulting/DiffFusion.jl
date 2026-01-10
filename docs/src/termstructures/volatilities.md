# Volatilities

## Volatility Term Structure Types

```@docs
DiffFusion.VolatilityTermstructure
```

```@docs
DiffFusion.BackwardFlatVolatility
```

```@docs
DiffFusion.backward_flat_volatility
```

```@docs
DiffFusion.flat_volatility
```

## Functions

Call operator for `VolatilityTermstructure` is defined as

    (ts::VolatilityTermstructure)(args...) = volatility(ts, args...)


```@docs
DiffFusion.volatility(
    ts::DiffFusion.VolatilityTermstructure,
    t::ModelTime,
    )
```

```@docs
DiffFusion.volatility(
    ts::DiffFusion.VolatilityTermstructure,
    t::ModelTime,
    x::ModelValue,
    )
```

```@docs
DiffFusion.volatility(
    ts::DiffFusion.BackwardFlatVolatility,
    t::ModelTime,
    )
```

```@docs
DiffFusion.time_idx(ts::DiffFusion.BackwardFlatVolatility, t)
```

