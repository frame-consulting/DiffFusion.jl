# Products

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

CombinedCashFlow

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

## Cash Flow and Coupon Methods

```@docs
DiffFusion.pay_time(cf::DiffFusion.CashFlow)
```

```@docs
DiffFusion.pay_time(cf::DiffFusion.CombinedCashFlow)
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
