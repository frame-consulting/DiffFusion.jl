# Model Parameters

## Parameter Term Structure Types

```@docs
DiffFusion.ParameterTermstructure
```

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

## Functions

Call operator for `ParameterTermstructure` is defined as

    (ts::ParameterTermstructure)(args...) = value(ts, args...)


```@docs
DiffFusion.value
```

```@docs
DiffFusion.time_idx(ts::DiffFusion.ForwardFlatParameter, t)
```
