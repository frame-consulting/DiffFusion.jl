# Futures, Inflation, Credit

## Futures Term Structure

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

## Inflation Term Structure

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

## Credit Default Term Structures

```@docs
DiffFusion.CreditDefaultTermstructure
```

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

Call operator for `CreditDefaultTermstructure` is defined as

    (ts::CreditDefaultTermstructure)(args...) = survival(ts, args...)


```@docs
DiffFusion.survival
```

