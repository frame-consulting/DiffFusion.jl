# Utilities Functions

In this section we document commonly used utility structures methods.

## Interpolation Methods

```@docs
DiffFusion.interpolation_methods
```

## Polynomial Regression Methods

```@docs
DiffFusion.PolynomialRegression
```

```@docs
DiffFusion.polynomial_regression
```

```@docs
DiffFusion.predict(reg::DiffFusion.PolynomialRegression, C::AbstractMatrix)
```

```@docs
DiffFusion.multi_index(n::Int, k::Int)
```

```@docs
DiffFusion.monomials(C::AbstractMatrix, V::AbstractMatrix)
```

## Pice-wise Polynomial Regression Methods

We implement a piece-wise polynomial multivariate regression.

The method represents a combination of a simple decision tree model
with polynomial regression on the leaf nodes.

For reference and motivation, see the following [blog post](https://towardsdatascience.com/linear-tree-the-perfect-mix-of-linear-model-and-decision-tree-2eaed21936b7).


We consider a data set of controls C of size (n,p). Here, n represents the
number of features and p represents the number of observations.

A *partitioning* is represented by a multi-index π = (π_1, ..., π_n)
with π_k > 0. Each π_k represents the number of partitions for the
k-th feature.

The idea is to sort C by the values of the first feature. Then, we split
the data set into π_1 partitions. For each partition the procedure is
repeated with the second feature and following features.

As a result, we get a split of the full data set into π_1 * ... * π_n
subsets. For each subset of data we calculate a polynomial regression.

For model prediction have a given data point c. We need to identify the
subset and regression which is to be used with c. This step is split
into the following sub-steps:

  1. Determine a multi-index α that identifies the subset.

  2. Determine a scalar index r via a total ordering of multi-
     indices.

The elements of α in step 1 are determined successively by means of
a *branching matrix* Q. A branching matrix is of size (π_k - 1, m_k).
Each column in Q represents quantiles that evenly split the calibration
data set for the k-th feature.

In order to determine an element α_k from c_k in step 1 we determine
the relevant column from the k-th branching matrix and compare c_k against
the quantile values.


```@docs
DiffFusion.PiecewiseRegression
```

```@docs
DiffFusion.piecewise_regression
```

```@docs
DiffFusion.predict(reg::DiffFusion.PiecewiseRegression, C::AbstractMatrix)
```

```@docs
DiffFusion.partition_index(π::Vector{Int}, α::Vector{Int})
```

```@docs
DiffFusion.sub_index(c_k::ModelValue, π::Vector{Int}, α::Vector{Int}, Q::AbstractMatrix)
```

```@docs
DiffFusion.multi_index(c::AbstractVector, π::Vector{Int}, Qs::AbstractVector)
```

```@docs
DiffFusion.branching_matrix(π::Vector{Int}, Alpha::Matrix{Int}, C_k::AbstractVector)
```

```@docs
DiffFusion.partitioning(C::AbstractMatrix, π::Vector{Int})
```

## Black Formula Methods

```@docs
DiffFusion.black_price
```

```@docs
DiffFusion.black_delta
```

```@docs
DiffFusion.black_gamma
```

```@docs
DiffFusion.black_theta
```

```@docs
DiffFusion.black_vega
```

```@docs
DiffFusion.black_implied_stdev
```

```@docs
DiffFusion.black_implied_volatility
```

## Bachelier Formula Methods

```@docs
DiffFusion.bachelier_price
```

```@docs
DiffFusion.bachelier_vega
```

```@docs
DiffFusion.bachelier_implied_stdev
```

```@docs
DiffFusion.bachelier_implied_volatility
```
