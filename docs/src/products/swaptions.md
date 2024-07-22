# Swaptions

European and Brmudan Swaptions are also represented as specific cash flow legs.

## European Swaption

```@docs
DiffFusion.SwaptionSettlement
```

```@docs
DiffFusion.SwaptionLeg
```

```@docs
DiffFusion.SwaptionLeg(
    alias::String,
    #
    expiry_time::ModelTime,
    settlement_time::ModelTime,
    float_coupons::AbstractVector,
    fixed_coupons::AbstractVector,
    payer_receiver::ModelValue,
    swap_disc_curve_key::String,
    settlement_type::DiffFusion.SwaptionSettlement,
    #
    notional::ModelValue,
    swpt_disc_curve_key::String = swap_disc_curve_key,
    swpt_fx_key::Union{String, Nothing} = nothing,
    swpt_long_short::ModelValue = +1.0,
    )
```

```@docs
DiffFusion.future_cashflows(leg::DiffFusion.SwaptionLeg, obs_time::ModelTime)
```

```@docs
DiffFusion.discounted_cashflows(leg::DiffFusion.SwaptionLeg, obs_time::ModelTime)
```

## Bermudan Swaption

```@docs
DiffFusion.BermudanExercise
```

```@docs
DiffFusion.bermudan_exercise(
    exercise_time::ModelTime,
    cashflow_legs::AbstractVector,
    make_regression_variables::Function,
    )
```

```@docs
DiffFusion.make_bermudan_exercises
```

```@docs
DiffFusion.BermudanSwaptionLeg
```

```@docs
DiffFusion.bermudan_swaption_leg
```

```@docs
DiffFusion.reset_regression!(
    leg::DiffFusion.BermudanSwaptionLeg,
    path::Union{DiffFusion.AbstractPath, Nothing} = nothing,
    make_regression::Union{Function, Nothing}  = nothing,
    )
```

```@docs
DiffFusion.discounted_cashflows(leg::DiffFusion.BermudanSwaptionLeg, obs_time::ModelTime)
```

