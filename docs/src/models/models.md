# Models Functions

In this section we document models for various risk factors.

## Data Structures and Constructors

```@docs
DiffFusion.Model
```

```@docs
DiffFusion.ComponentModel
```

```@docs
DiffFusion.AssetModel
```

```@docs
DiffFusion.LognormalAssetModel
```

```@docs
DiffFusion.lognormal_asset_model
```

```@docs
DiffFusion.SeparableHjmModel
```

```@docs
DiffFusion.GaussianHjmModel
```

```@docs
DiffFusion.gaussian_hjm_model(
    alias::String,
    delta::DiffFusion.ParameterTermstructure,
    chi::DiffFusion.ParameterTermstructure,
    sigma_f::DiffFusion.BackwardFlatVolatility,
    correlation_holder::Union{DiffFusion.CorrelationHolder, Nothing},
    quanto_model::Union{DiffFusion.AssetModel, Nothing},
    )
```

```@docs
DiffFusion.MarkovFutureModel
```

```@docs
DiffFusion.markov_future_model
```

```@docs
DiffFusion.CompositeModel
```

```@docs
DiffFusion.SimpleModel
```

```@docs
DiffFusion.simple_model
```

## State Variable

A model allows to simulate a stochastic process $\left(X_t\right)$. For a given $t$ the vector $X_t$ is represented by a `ModelState`. 

```@docs
DiffFusion.ModelState
```

```@docs
DiffFusion.model_state
```

```@docs
DiffFusion.alias_dictionary
```

## Auxilliary Methods

```@docs
DiffFusion.alias(m::DiffFusion.Model)
```

```@docs
DiffFusion.model_alias
```

```@docs
DiffFusion.state_alias
```

```@docs
DiffFusion.factor_alias
```

```@docs
DiffFusion.parameter_grid
```

## Model Functions for Payoff Evaluation

```@docs
DiffFusion.log_asset
```

```@docs
DiffFusion.log_bank_account
```

```@docs
DiffFusion.log_zero_bond
```

```@docs
DiffFusion.log_zero_bonds
```

```@docs
DiffFusion.log_compounding_factor
```

```@docs
DiffFusion.log_asset_convexity_adjustment
```

```@docs
DiffFusion.log_future
```

```@docs
DiffFusion.forward_rate_variance
```

```@docs
DiffFusion.swap_rate_variance
```

## Model Functions for Simulation

```@docs
DiffFusion.Theta
```

```@docs
DiffFusion.H_T
```

```@docs
DiffFusion.Sigma_T
```

```@docs
DiffFusion.state_dependent_Theta
```

```@docs
DiffFusion.state_dependent_H
```

```@docs
DiffFusion.state_dependent_Sigma
```

```@docs
DiffFusion.state_alias_H
```

```@docs
DiffFusion.factor_alias_Sigma
```

```@docs
DiffFusion.covariance
```

```@docs
DiffFusion.volatility_and_correlation
```

```@docs
DiffFusion.simulation_parameters
```

```@docs
DiffFusion.diagonal_volatility
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

