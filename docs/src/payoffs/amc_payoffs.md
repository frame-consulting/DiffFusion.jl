# American Monte Carlo

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

```@docs
DiffFusion.calibrate_regression
```

```@docs
DiffFusion.has_amc_payoff
```

