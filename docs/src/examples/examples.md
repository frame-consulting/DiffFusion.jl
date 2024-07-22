# Example Models and Portfolios

We add example models, term structures, pricing context and product configurations in an `Examples` sub-module. The examples are encoded as YAML files. They should help users to easily set up simulations for ad-hoc testing and analysis.

In this section we document data and functions to work with the product and model examples.

```@docs
DiffFusion.Examples._yaml_path
```

```@docs
DiffFusion.Examples._csv_path
```

```@docs
DiffFusion.Examples.examples
```

```@docs
DiffFusion.Examples.load
```

```@docs
DiffFusion.Examples.build
```

```@docs
DiffFusion.Examples.get_object
```

## Model Setup

```@docs
DiffFusion.Examples.model
```

```@docs
DiffFusion.Examples.correlation_holder
```

```@docs
DiffFusion.Examples.context
```

```@docs
DiffFusion.Examples.term_structures
```

```@docs
DiffFusion.Examples.simulation!
```

```@docs
DiffFusion.Examples.path!
```

## Product Setup


```@docs
DiffFusion.Examples.fixed_rate_leg
```

```@docs
DiffFusion.Examples.simple_rate_leg
```

```@docs
DiffFusion.Examples.compounded_rate_leg
```

```@docs
DiffFusion.Examples.random_swap
```

```@docs
DiffFusion.Examples.random_swaption
```

```@docs
DiffFusion.Examples.random_bermudan
```

```@docs
DiffFusion.Examples.portfolio!
```

```@docs
DiffFusion.Examples.display_portfolio
```

```@docs
DiffFusion.Examples.scenarios!
```
