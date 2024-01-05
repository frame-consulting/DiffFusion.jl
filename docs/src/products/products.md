# Products Functions

In this section we document product objects and methods.

## Cash Flow and Coupon Types

```@docs
DiffFusion.CashFlow
```

```@docs
DiffFusion.CombinedCashFlow
```

```@docs
DiffFusion.combined_cashflow
```

```@docs
DiffFusion.Coupon
```

```@docs
DiffFusion.FixedCashFlow
```

```@docs
DiffFusion.FixedRateCoupon
```

```@docs
DiffFusion.SimpleRateCoupon
```

```@docs
DiffFusion.CompoundedRateCoupon
```

```@docs
DiffFusion.OptionletCoupon
```

```@docs
DiffFusion.OptionletCoupon(
    expiry_time::ModelTime,
    coupon::Union{DiffFusion.SimpleRateCoupon, DiffFusion.CompoundedRateCoupon},
    strike_rate::ModelValue,
    call_put::ModelValue,
    )
```

```@docs
DiffFusion.OptionletCoupon(
    coupon::Union{DiffFusion.SimpleRateCoupon, DiffFusion.CompoundedRateCoupon},
    strike_rate::ModelValue,
    call_put::ModelValue,
    )
```

## Cash Flow and Coupon Methods

```@docs
DiffFusion.pay_time(cf::DiffFusion.CashFlow)
```

```@docs
DiffFusion.pay_time(cf::DiffFusion.CombinedCashFlow)
```

```@docs
DiffFusion.pay_time(cf::DiffFusion.OptionletCoupon)
```

```@docs
DiffFusion.first_time
```

```@docs
DiffFusion.amount(cf::DiffFusion.CashFlow)
```

```@docs
DiffFusion.expected_amount(cf::DiffFusion.CashFlow, obs_time::ModelTime)
```

```@docs
DiffFusion.year_fraction(cf::DiffFusion.Coupon)
```

```@docs
DiffFusion.coupon_rate(cf::DiffFusion.Coupon)
```

```@docs
DiffFusion.forward_rate(cf::DiffFusion.Coupon, obs_time::ModelTime)
```

## Cash Flow Legs

```@docs
DiffFusion.CashFlowLeg
```

```@docs
DiffFusion.DeterministicCashFlowLeg
```

```@docs
DiffFusion.cashflow_leg
```

```@docs
DiffFusion.MtMCashFlowLeg
```

```@docs
DiffFusion.mtm_cashflow_leg
```

```@docs
DiffFusion.CashBalanceLeg
```

```@docs
DiffFusion.cash_balance_leg
```

```@docs
DiffFusion.AssetLeg
```

```@docs
DiffFusion.future_cashflows(leg::DiffFusion.CashFlowLeg, obs_time::ModelTime)
```

```@docs
DiffFusion.discounted_cashflows(leg::DiffFusion.CashFlowLeg, obs_time::ModelTime)
```

## Swaption Cash Flow Legs

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

## Common Methods Overview

```@docs
DiffFusion.amount
```

```@docs
DiffFusion.coupon_rate
```

```@docs
DiffFusion.discounted_cashflows
```

```@docs
DiffFusion.expected_amount
```

```@docs
DiffFusion.forward_rate
```

```@docs
DiffFusion.future_cashflows
```

```@docs
DiffFusion.year_fraction
```
