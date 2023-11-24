# Additional Rates Model Functions

## Model Functions for Simulation

```@docs
DiffFusion.func_y
```

```@docs
DiffFusion.chi_hjm
```

```@docs
DiffFusion.benchmark_times
```

```@docs
DiffFusion.H_hjm
```

```@docs
DiffFusion.G_hjm
```

```@docs
DiffFusion.benchmark_times_scaling
```

```@docs
DiffFusion.func_Theta_x
```

```@docs
DiffFusion.func_Theta_x_integrate_y
```

```@docs
DiffFusion.func_Theta_s
```

```@docs
DiffFusion.func_Theta
```

```@docs
DiffFusion.func_H_T
```

```@docs
DiffFusion.func_H_T_dense
```

```@docs
DiffFusion.func_Sigma_T
```

## Swap Rate Volatility Calculation

```@docs
DiffFusion.GaussianHjmModelVolatility
```

```@docs
DiffFusion.swap_rate_gradient
```

```@docs
DiffFusion.swap_rate_instantaneous_covariance
```

```@docs
DiffFusion.swap_rate_volatility²
```

```@docs
DiffFusion.swap_rate_covariance
```

```@docs
DiffFusion.swap_rate_correlation
```

```@docs
DiffFusion.model_implied_volatilties
```

## Model Calibration

```@docs
DiffFusion.gaussian_hjm_model(
    alias::String,
    ch::Union{DiffFusion.CorrelationHolder, Nothing},
    option_times::AbstractVector,
    swap_maturities::AbstractVector,
    swap_rate_volatilities::AbstractMatrix,
    yts::DiffFusion.YieldTermstructure;
    max_iter::Integer = 5,
    volatility_regularisation::ModelValue = 0.0,
    )
```

```@docs
DiffFusion.gaussian_hjm_model(
    alias::String,
    delta::DiffFusion.ParameterTermstructure,
    chi::DiffFusion.ParameterTermstructure,
    ch::Union{DiffFusion.CorrelationHolder, Nothing},
    option_times::AbstractVector,
    swap_maturities::AbstractVector,
    swap_rate_volatilities::AbstractMatrix,
    yts::DiffFusion.YieldTermstructure;
    max_iter::Integer = 5,
    volatility_regularisation::ModelValue = 0.0,
    )
```
