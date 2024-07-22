# Common Model Functions

## Abstract Model Types

```@docs
DiffFusion.Model
```

```@docs
DiffFusion.ComponentModel
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
