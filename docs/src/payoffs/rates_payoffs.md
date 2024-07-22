# Interest Rates

## Building Blocks

```@docs
DiffFusion.Numeraire
```

```@docs
DiffFusion.BankAccount
```

```@docs
DiffFusion.ZeroBond
```

```@docs
DiffFusion.Fixing
```

## Rates Payoffs

```@docs
DiffFusion.LiborRate
```

```@docs
DiffFusion.LiborRate(
    obs_time::ModelTime,
    start_time::ModelTime,
    end_time::ModelTime,
    key::String,
    )
```

```@docs
DiffFusion.CompoundedRate
```

```@docs
DiffFusion.CompoundedRate(
    obs_time::ModelTime,
    start_time::ModelTime,
    end_time::ModelTime,
    key::String,
    )
```

```@docs
DiffFusion.Optionlet
```

```@docs
DiffFusion.Optionlet(
    obs_time_::ModelTime,
    expiry_time::ModelTime,
    forward_rate::Union{DiffFusion.LiborRate, DiffFusion.CompoundedRate},
    strike_rate::DiffFusion.Payoff,
    call_put::ModelValue,
    gearing_factor::DiffFusion.Payoff = DiffFusion.Fixed(1.0),
    )
```

```@docs
DiffFusion.Swaption
```

```@docs
DiffFusion.Swaption(
    obs_time_::ModelTime,
    expiry_time::ModelTime,
    settlement_time::ModelTime,
    forward_rates::AbstractVector,
    fixed_times::AbstractVector,
    fixed_weights::AbstractVector,
    fixed_rate::ModelValue,
    payer_receiver::ModelValue,
    disc_key::String,
    )
```
