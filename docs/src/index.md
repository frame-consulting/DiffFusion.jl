# DiffFusion.jl \[∂F\]

Documentation for DiffFusion.jl.

The DiffFusion.jl package implements a framework for joint simulation of financial risk factors, risk-neutral valuation of financial instruments and calculation of portfolio risk measures.

The intended purpose of the package is efficient exposure simulation for XVA and Counterparty Credit Risk (CCR).

## Repository

The code for DiffFusion.jl is hosted at [github.com/frame-consulting/DiffFusion.jl](https://github.com/frame-consulting/DiffFusion.jl).

## Installation

The most recent release of the package can be installed via

```
using Pkg; Pkg.add("DiffFusion.jl")
```

Unit tests can be run via

```
Pkg.test("DiffFusion")
```

For details on the functionality, see the [Overview](@ref) page.

For questions please contact [info@frame-consult.de](mailto:info@frame-consult.de).

## Getting Started

The best way of getting started with the DiffFusion framework is to have a look at the test suite.

An example for exposure simulation of a Vanilla swap portfolio is implemented in the [scenario generation](https://github.com/frame-consulting/DiffFusion.jl/blob/main/test/componenttests/scenarios.jl) component test.

Individual examples on model, simulation and product setup can be found in the [unit tests](https://github.com/frame-consulting/DiffFusion.jl/tree/main/test/unittests).
