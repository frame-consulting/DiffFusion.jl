# Term Structures

In this section we document term structures.

## Term Structure Types and Methods

```@docs
DiffFusion.Termstructure
```

```@docs
DiffFusion.alias(ts::DiffFusion.Termstructure)
```

```@docs
DiffFusion.TermstructureResultSize
```

### CorrelationTermstructure

```@docs
DiffFusion.CorrelationTermstructure
```

Call operator for `CorrelationTermstructure` is defined as

    (ts::CorrelationTermstructure)(args...) = correlation(ts, args...)


```@docs
DiffFusion.correlation(
    ts::DiffFusion.CorrelationTermstructure,
    alias1::String,
    alias2::String,
    )
```

```@docs
DiffFusion.DiffFusion.correlation(
    ts::DiffFusion.CorrelationTermstructure,
    aliases::AbstractVector{String},
    )
```

```@docs
DiffFusion.correlation(
    ts::DiffFusion.CorrelationTermstructure,
    aliases1::AbstractVector{String},
    aliases2::AbstractVector{String},
    )
```

```@docs
DiffFusion.correlation(
    ts::DiffFusion.CorrelationTermstructure,
    alias1::String,
    aliases2::AbstractVector{String},
    )
```

```@docs
DiffFusion.correlation(
    ts::DiffFusion.CorrelationTermstructure,
    aliases1::AbstractVector{String},
    alias2::String,
    )
```

### CreditDefaultTermstructure


```@docs
DiffFusion.CreditDefaultTermstructure
```

Call operator for `CreditDefaultTermstructure` is defined as

    (ts::CreditDefaultTermstructure)(args...) = survival(ts, args...)


```@docs
DiffFusion.survival(
    ts::DiffFusion.CreditDefaultTermstructure,
    t::ModelTime,
    )
```

### FuturesTermstructure

```@docs
DiffFusion.FuturesTermstructure
```

Call operator for `FuturesTermstructure` is defined as

    (ts::FuturesTermstructure)(args...) = future_price(ts, args...)


```@docs
DiffFusion.future_price(
    ts::DiffFusion.FuturesTermstructure,
    t::ModelTime,
    )
```

### InflationTermstructure

```@docs
DiffFusion.InflationTermstructure
```

Call operator for `InflationTermstructure` is defined as

    (ts::InflationTermstructure)(args...) = inflation_index(ts, args...)


```@docs
DiffFusion.inflation_index(
    ts::DiffFusion.InflationTermstructure,
    t::ModelTime,
    )
```

### ParameterTermstructure

```@docs
DiffFusion.ParameterTermstructure
```

Call operator for `ParameterTermstructure` is defined as

    (ts::ParameterTermstructure)(args...) = value(ts, args...)


```@docs
DiffFusion.value(
    ts::DiffFusion.ParameterTermstructure,
    result_size::DiffFusion.TermstructureResultSize = DiffFusion.TermstructureVector,
    )
```

```@docs
DiffFusion.value(
    ts::DiffFusion.ParameterTermstructure,
    t::ModelTime,
    result_size::DiffFusion.TermstructureResultSize = DiffFusion.TermstructureVector,
    )
```

### YieldTermstructure

```@docs
DiffFusion.YieldTermstructure
```

Call operator for `YieldTermstructure` is defined as

    (ts::YieldTermstructure)(args...) = discount(ts, args...)


```@docs
DiffFusion.discount(
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

```@docs
DiffFusion.zero_rate(
    ts::DiffFusion.YieldTermstructure,
    t::ModelTime,
    )
```

```@docs
DiffFusion.forward_rate(
    ts::DiffFusion.YieldTermstructure,
    t::ModelTime,
    dt=1.0e-6,
    )
```

### VolatilityTermstructure

```@docs
DiffFusion.VolatilityTermstructure
```

Call operator for `VolatilityTermstructure` is defined as

    (ts::VolatilityTermstructure)(args...) = volatility(ts, args...)


```@docs
DiffFusion.volatility(
    ts::DiffFusion.VolatilityTermstructure,
    t::ModelTime,
    result_size::DiffFusion.TermstructureResultSize = DiffFusion.TermstructureVector,
    )
```

```@docs
DiffFusion.volatility(
    ts::DiffFusion.VolatilityTermstructure,
    t::ModelTime,
    x::ModelValue,
    )
```


## Yield Term Structures

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
DiffFusion.interpolation_methods
```


## Common Methods Overview

```@docs
DiffFusion.correlation
```

```@docs
DiffFusion.discount
```

```@docs
DiffFusion.value
```

```@docs
DiffFusion.volatility
```

```@docs
DiffFusion.survival
```
