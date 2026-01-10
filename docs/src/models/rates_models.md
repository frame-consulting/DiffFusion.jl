# Interest Rates Models

## Model Types

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
    scaling_type::DiffFusion.BenchmarkTimesScaling = DiffFusion._default_benchmark_time_scaling,
    )
```

```@docs
DiffFusion.QuasiGaussianModel
```

```@docs
DiffFusion.quasi_gaussian_model
```

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
DiffFusion.BenchmarkTimesScaling
```

```@docs
DiffFusion.benchmark_times_scaling
```

```@docs
DiffFusion.benchmark_times_scaling_forward_rate
```

```@docs
DiffFusion.benchmark_times_scaling_zero_rate
```

```@docs
DiffFusion.benchmark_times_scaling_diagonal
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

```@docs
DiffFusion.func_sigma_f
```

```@docs
DiffFusion.func_sigma_T
```

```@docs
DiffFusion.func_sigma_T_hyb
```

```@docs
DiffFusion.auxiliary_variable
```

```@docs
DiffFusion.integrated_state_variable
```

```@docs
DiffFusion.stochastic_volatility
```

## Model Functions for Payoff Evaluation

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
DiffFusion.forward_rate_variance
```

```@docs
DiffFusion.swap_rate_variance
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

## Functors for Simulation Functions

```@docs
DiffFusion.HjmHybridVolatility
```

```@docs
DiffFusion.GaussianHybridVolatility
```

```@docs
DiffFusion.QuasiGaussianHybridVolatility
```

```@docs
DiffFusion.HjmAuxiliaryVariable
```

```@docs
DiffFusion.GaussianHjmAuxiliaryVariable
```

```@docs
DiffFusion.QuasiGaussianAuxiliaryVariable
```

```@docs
DiffFusion.HjmThetaIntegrand
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
