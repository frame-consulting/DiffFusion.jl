# Payoffs

In this section we document the payoff scripting framework.

## Interface

```@docs
DiffFusion.Payoff
```

```@docs
DiffFusion.Leaf
```

```@docs
DiffFusion.UnaryNode
```

```@docs
DiffFusion.BinaryNode
```

```@docs
DiffFusion.obs_time(p::DiffFusion.Payoff)
```

```@docs
DiffFusion.obs_times(p::DiffFusion.Payoff)
```

```@docs
DiffFusion.at(p::DiffFusion.Payoff, path::DiffFusion.AbstractPath)
```

## Basic Payoffs

```@docs
DiffFusion.Fixed
```

```@docs
DiffFusion.ScalarValue
```

```@docs
DiffFusion.Pay
```

```@docs
DiffFusion.Cache
```

## Mathematical Operations

The following payoffs are created by operator overloading of `+`, `-`, `*`, `/` and logical operators.

```@docs
DiffFusion.Add
```

```@docs
DiffFusion.Sub
```

```@docs
DiffFusion.Mul
```

```@docs
DiffFusion.Div
```

```@docs
DiffFusion.Logical
```

## Mathematical Functions

```@docs
DiffFusion.Exp
```

```@docs
DiffFusion.Log
```

```@docs
DiffFusion.Max
```

```@docs
DiffFusion.Min
```

## Common Payoff Methods Overview

```@docs
DiffFusion.obs_time
```

```@docs
DiffFusion.obs_times
```

```@docs
DiffFusion.at
```

```@docs
DiffFusion.string
```
