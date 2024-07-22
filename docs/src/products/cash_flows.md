# Cash Flow and Coupons

Cash flows and coupons are the building blocks for financial instruments.

## Basic Cash Flows

```@docs
DiffFusion.CashFlow
```

```@docs
DiffFusion.FixedCashFlow
```

```@docs
DiffFusion.CombinedCashFlow
```

```@docs
DiffFusion.combined_cashflow
```

## Coupons

```@docs
DiffFusion.Coupon
```

## Interest Rate Coupons

```@docs
DiffFusion.FixedRateCoupon
```

```@docs
DiffFusion.SimpleRateCoupon
```

```@docs
DiffFusion.CompoundedRateCoupon
```

## Caplets and Floorlets

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

## Inflation Coupons

```@docs
DiffFusion.RelativeReturnCoupon
```

```@docs
DiffFusion.RelativeReturnIndexCoupon
```

## Vanilla Options

```@docs
DiffFusion.VanillaAssetOptionFlow
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
DiffFusion.amount
```

```@docs
DiffFusion.expected_amount
```

```@docs
DiffFusion.year_fraction
```

```@docs
DiffFusion.coupon_rate
```

```@docs
DiffFusion.forward_rate(cf::DiffFusion.Coupon, obs_time::ModelTime)
```

```@docs
DiffFusion.forward_rate(cf::DiffFusion.FixedRateCoupon, obs_time::ModelTime)
```

```@docs
DiffFusion.forward_rate(cf::DiffFusion.SimpleRateCoupon, obs_time::ModelTime)
```

```@docs
DiffFusion.forward_rate(cf::DiffFusion.CompoundedRateCoupon, obs_time::ModelTime)
```

```@docs
DiffFusion.forward_rate(cf::DiffFusion.OptionletCoupon, obs_time::ModelTime)
```

```@docs
DiffFusion.forward_rate(cf::DiffFusion.RelativeReturnCoupon, obs_time::ModelTime)
```

```@docs
DiffFusion.forward_rate(cf::DiffFusion.RelativeReturnIndexCoupon, obs_time::ModelTime)
```
