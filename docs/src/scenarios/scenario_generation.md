# Scenarios

## Scenario Cube

```@docs
DiffFusion.ScenarioCube
```

## Pricing Scenarios

```@docs
DiffFusion.scenarios
```

## Scenario Cube Operations

```@docs
DiffFusion.join_scenarios
```

```@docs
DiffFusion.interpolate_scenarios
```

```@docs
DiffFusion.concatenate_scenarios
```

```@docs
DiffFusion.aggregate
```

## Scenario Generation Using Parallel Computations

We implement various strategies for parallelisation of scenario generation: multi-threading multi-processing and a mixed approach.

It turns out that Julia's garbage collection impedes scaling properties of multi-threaded scenario generation. Parallel garbage collection introduced with Julia 1.10 does not seem to help.

Fortunately, multi-processing can be used efficiently for scenario generation. This circumvents the garbage collection limitation.

We also find that a combination of multi-processing and multi-threading can be most efficient. With such a mixed approach we can leverage the lower overhead from multi-threading and mitigate the impact of single-threaded garbage collection.


```@docs
DiffFusion.scenarios_parallel
```

```@docs
DiffFusion.scenarios_multi_threaded
```

```@docs
DiffFusion.scenarios_distributed
```
