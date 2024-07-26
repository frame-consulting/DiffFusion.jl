# Asset Models (FX/Equity/Inflation)

## Asset Model Types

```@docs
DiffFusion.AssetModel
```

### Lognormal Model

```@docs
DiffFusion.LognormalAssetModel
```

```@docs
DiffFusion.lognormal_asset_model
```

### CEV Model

```@docs
DiffFusion.CevAssetModel
```

```@docs
DiffFusion.cev_asset_model
```

## Model Functions for Payoff Evaluation

```@docs
DiffFusion.log_asset
```

```@docs
DiffFusion.log_asset_convexity_adjustment
```

## Additional Asset Model Functions

```@docs
DiffFusion.asset_volatility
```

```@docs
DiffFusion.correlation_holder(m::DiffFusion.AssetModel)
```

```@docs
DiffFusion.quanto_drift
```

```@docs
DiffFusion.asset_variance
```

