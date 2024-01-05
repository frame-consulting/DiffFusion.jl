# Analytics Functions

In this section we document methods for instrument pricing, exposure and collateral simulation.

```@docs
DiffFusion.ScenarioCube
```

```@docs
DiffFusion.scenarios
```

```@docs
DiffFusion.join_scenarios
```

```@docs
DiffFusion.interpolate_scenarios
```

```@docs
DiffFusion.concatenate_scenarios
```

```@docs
DiffFusion.aggregate
```

```@docs
DiffFusion.expected_exposure
```

```@docs
DiffFusion.potential_future_exposure
```

```@docs
DiffFusion.valuation_adjustment
```

## Collateral Modelling

This section contains methods for collateralised exposure calculation.

We follow the approaches in A. Green, XVA, 2016.


```@docs
DiffFusion.collateral_call_times
```

```@docs
DiffFusion.market_values_for_csa
```

```@docs
DiffFusion.collateral_values_for_csa
```

```@docs
DiffFusion.effective_collateral_values
```

```@docs
DiffFusion.collateralised_portfolio
```

## Pricing Analytics

```@docs
DiffFusion.model_price
```

```@docs
DiffFusion.model_price_and_deltas
```

```@docs
DiffFusion.model_price_and_vegas
```

```@docs
DiffFusion.model_price_and_deltas_vector
```

```@docs
DiffFusion.model_price_and_vegas_vector
```
