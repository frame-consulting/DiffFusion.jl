# Correlations

## Correlation Term Structure Type

```@docs
DiffFusion.CorrelationTermstructure
```

```@docs
DiffFusion.CorrelationHolder
```

```@docs
DiffFusion.correlation_holder
```

## Functions

Call operator for `CorrelationTermstructure` is defined as

    (ts::CorrelationTermstructure)(args...) = correlation(ts, args...)

```@docs
DiffFusion.correlation
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

