# Serialisation Functions

In this section we document methods for serialising and de-serialising objects.

We serialise objects into ordered dictionaries of the general form

    typename : TypeName
    constructor : function_name
    field_name_1 : field_value_1
    ...
    field_name_n : field_value_n

Dictionary keys are strings, dictionary values are strings, numbers o
ordered dictionaries of component structures.

We utilise multiple dispatch to specify serialisation recursively.

## Object Serialisation

```@docs
DiffFusion.serialise
```

```@docs
DiffFusion.serialise_struct
```

```@docs
DiffFusion._serialise_key_references
```

```@docs
DiffFusion.serialise_key
```

```@docs
DiffFusion.serialise_as_list
```

## Object De-Serialisation

```@docs
DiffFusion.deserialise
```

```@docs
DiffFusion.deserialise_object
```

```@docs
DiffFusion.deserialise_from_list
```

```@docs
DiffFusion.array
```

## Rebuild Models

This subsection contains methods to extract term structures and re-build models.

Methods are intended to be used for sensitivity calculations. For that
purpose we need to identify model parameters as inputs to the valuation
function.

Model parameters for a model `m::Model` are stored in a `Dict{String, Any}` of the form

    "type" => typeof(m),
    "alias" => m.alias,
    [parameter identifier] => [parameter value(s)]
    ...


```@docs
DiffFusion.model_parameters
```

```@docs
DiffFusion.build_model
```

```@docs
DiffFusion.termstructure_values
```

```@docs
DiffFusion.termstructure_dictionary!
```

```@docs
DiffFusion.model_volatility_values
```

```@docs
DiffFusion.model_parameters!
```

## Read Term Structures From CSV Files

```@docs
DiffFusion.read_zero_curves
```

```@docs
DiffFusion.read_volatilities
```

```@docs
DiffFusion.read_volatility
```

```@docs
DiffFusion.read_parameters
```

```@docs
DiffFusion.read_correlations
```
