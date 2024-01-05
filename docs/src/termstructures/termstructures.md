# Term Structures Functions

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


## Correlation Term Structures

```@docs
DiffFusion.CorrelationHolder
```

```@docs
DiffFusion.correlation_holder
```

```@docs
DiffFusion.correlation_key
```

```@docs
DiffFusion.set_correlation!
```

```@docs
DiffFusion.get
```

## Credit Default Term Structures

```@docs
DiffFusion.FlatSpreadCurve
```

```@docs
DiffFusion.flat_spread_curve
```

```@docs
DiffFusion.LogSurvivalCurve
```

```@docs
DiffFusion.survival_curve
```

## Parameter Term Structures

```@docs
DiffFusion.PiecewiseFlatParameter
```

```@docs
DiffFusion.BackwardFlatParameter
```

```@docs
DiffFusion.backward_flat_parameter
```

```@docs
DiffFusion.flat_parameter
```

```@docs
DiffFusion.ForwardFlatParameter
```

```@docs
DiffFusion.forward_flat_parameter
```

```@docs
DiffFusion.time_idx(ts::DiffFusion.BackwardFlatParameter, t)
```

```@docs
DiffFusion.time_idx(ts::DiffFusion.ForwardFlatParameter, t)
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
DiffFusion.LinearZeroCurve
```

```@docs
DiffFusion.linear_zero_curve
```

## Volatility Term Structures

```@docs
DiffFusion.BackwardFlatVolatility
```

```@docs
DiffFusion.backward_flat_volatility
```

```@docs
DiffFusion.flat_volatility
```

```@docs
DiffFusion.time_idx(ts::DiffFusion.BackwardFlatVolatility, t)
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
