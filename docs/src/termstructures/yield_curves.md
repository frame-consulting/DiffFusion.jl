# Yield Curves

## Yield Term Structure Types

```@docs
DiffFusion.YieldTermstructure
```

```@docs
DiffFusion.FlatForward
```

```@docs
DiffFusion.flat_forward
```

```@docs
DiffFusion.ZeroCurve
```

```@docs
DiffFusion.zero_curve
```

```@docs
DiffFusion.LinearZeroCurve
```

```@docs
DiffFusion.linear_zero_curve
```

## Functions

### Discount Factor Calculation

Call operator for `YieldTermstructure` is defined as

    (ts::YieldTermstructure)(args...) = discount(ts, args...)


```@docs
DiffFusion.discount(
    ts::DiffFusion.YieldTermstructure,
    t::ModelTime,
    )
```

```@docs
DiffFusion.discount(
    ts::DiffFusion.FlatForward,
    t::ModelTime,
    )
```

```@docs
DiffFusion.discount(
    ts::DiffFusion.ZeroCurve,
    t::ModelTime,
    )
```

```@docs
DiffFusion.discount(
    ts::DiffFusion.LinearZeroCurve,
    t::ModelTime,
    )
```

### Zero Rate Calculation

```@docs
DiffFusion.zero_rate(
    ts::DiffFusion.YieldTermstructure,
    t::ModelTime,
    )
```

```@docs
DiffFusion.zero_rate(
    ts::DiffFusion.YieldTermstructure,
    t0::ModelTime,
    t1::ModelTime,
    )
```

### Forward Rate Calculation

```@docs
DiffFusion.forward_rate(
    ts::DiffFusion.YieldTermstructure,
    t::ModelTime,
    dt=1.0e-6,
    )
```

