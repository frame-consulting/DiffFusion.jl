# Basic Products

Financial instruments are decomposed into legs.

A product is a collection of one or more legs.

## Basic Cash Flow Legs

```@docs
DiffFusion.CashFlowLeg
```

```@docs
DiffFusion.DeterministicCashFlowLeg
```

```@docs
DiffFusion.cashflow_leg
```

## Cross Currency Swap Legs 

```@docs
DiffFusion.MtMCashFlowLeg
```

```@docs
DiffFusion.mtm_cashflow_leg
```

## Cash and Assets

```@docs
DiffFusion.CashBalanceLeg
```

```@docs
DiffFusion.cash_balance_leg
```

```@docs
DiffFusion.AssetLeg
```

## Cash Flow Leg Functions

### Future Cash Flows (Undiscounted)

```@docs
DiffFusion.future_cashflows(leg::DiffFusion.CashFlowLeg, obs_time::ModelTime)
```

```@docs
DiffFusion.future_cashflows(leg::DiffFusion.DeterministicCashFlowLeg, obs_time::ModelTime)
```

```@docs
DiffFusion.future_cashflows(leg::DiffFusion.MtMCashFlowLeg, obs_time::ModelTime)
```

```@docs
DiffFusion.future_cashflows(leg::DiffFusion.AssetLeg, obs_time::ModelTime)
```

```@docs
DiffFusion.future_cashflows(leg::DiffFusion.CashBalanceLeg, obs_time::ModelTime)
```

### Discounted Cash Flows

```@docs
DiffFusion.discounted_cashflows(leg::DiffFusion.CashFlowLeg, obs_time::ModelTime)
```

```@docs
DiffFusion.discounted_cashflows(leg::DiffFusion.DeterministicCashFlowLeg, obs_time::ModelTime)
```

```@docs
DiffFusion.discounted_cashflows(leg::DiffFusion.MtMCashFlowLeg, obs_time::ModelTime)
```

```@docs
DiffFusion.discounted_cashflows(leg::DiffFusion.AssetLeg, obs_time::ModelTime)
```

```@docs
DiffFusion.discounted_cashflows(leg::DiffFusion.CashBalanceLeg, obs_time::ModelTime)
```
