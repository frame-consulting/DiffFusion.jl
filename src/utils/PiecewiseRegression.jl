
"""
We implement a piece-wise polynomial multivariate regression.

The method represents a combination of a simple decision tree model
with polynomial regression on the leaf nodes.

For reference and motivation, see

https://towardsdatascience.com/linear-tree-the-perfect-mix-of-linear-model-and-decision-tree-2eaed21936b7

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
"""

"""
    partition_index(π::Vector{Int}, α::Vector{Int})

Calculate a scalar index r from a multi-index α and a partitioning π.

This method implements a total ordering of multi-indices.
"""
function partition_index(π::Vector{Int}, α::Vector{Int})
    basis = [ prod(π[j+1:end]) for j in 1:length(α) ]
    return basis' * (α .- 1) + 1
end


"""
    sub_index(c_k::ModelValue, π::Vector{Int}, α::Vector{Int}, Q::AbstractMatrix)

Calculate the k-th index α_k for a scalar feature c_k, earlier indices
α = (α_1, ..., α_k-1), partitioning π = (π_1, ..., π_k) up to index k
and a branching matrix Q.
"""
function sub_index(c_k::ModelValue, π::Vector{Int}, α::Vector{Int}, Q::AbstractMatrix)
    @assert length(π) == length(α) + 1
    for j in 1:length(α)
        @assert (1 ≤ α[j]) && (α[j] ≤ π[j])
    end
    @assert π[end] > 0
    # branching matrix must be consistent to partitioning
    m_j = 1  # if length(π) == 1
    if length(π) > 1
        m_j = prod(π[begin:end-1])
    end
    @assert size(Q) == (π[end]-1, m_j)
    # Now, we can come to the actual calculation...
    if π[end] == 1
        return 1
    end
    r = partition_index(π[begin:end-1], α)
    α_k = searchsortedfirst(Q[:,r], c_k)
    return α_k
end


"""
    multi_index(c::AbstractVector, π::Vector{Int}, Qs::AbstractVector)

Calculate a multi-index α = (α_1, ..., α_n). For the elements we have
1 ≤ α_k ≤ π_k. An element α_k represents the index of the subset to
which the k-th feature c_k belongs (all conditional on earlier features).
"""
function multi_index(c::AbstractVector, π::Vector{Int}, Qs::AbstractVector)
    @assert length(c) == length(π)
    @assert length(c) == length(Qs)
    α = Int[]
    for k in 1:length(c)
        α_k = sub_index(c[k], π[begin:k], α, Qs[k])
        α = vcat(α, α_k)
    end
    return α
end


"""
    branching_matrix(π::Vector{Int}, Alpha::Matrix{Int}, C_k::AbstractVector)

Calculate a branching matrix Q_k of quantiles for a vector of features
(c_k,j)_j=1,..,p. Calculation also depends on earlier multi-indices
α = (α_1, ..., α_k-1) for each c_k,j and partitions π = (π_1, ..., π_k-1).
"""
function branching_matrix(π::Vector{Int}, Alpha::Matrix{Int}, C_k::AbstractVector)
    @assert size(Alpha) == (length(π) - 1, length(C_k))
    # we double-check indices to catch wrong inputs
    for i in 1:(length(π) - 1)
        @assert all(1 .≤ Alpha[i,:])
        @assert all(Alpha[i,:] .≤ π[i])
    end
    @assert π[end] > 0
    m_j = 1  # if length(π) == 1
    if length(π) > 1
        m_j = prod(π[begin:end-1])
    end
    if π[end] == 1  # this case is degenerate; we do not do any partitioning
        return zeros(0, m_j)
    end
    quantiles = [ t/π[end] for t in 1:(π[end]-1) ]
    P = [ partition_index(π[begin:end-1], Alpha[:,j]) for j in 1:size(Alpha)[2] ]
    Q = [ quantile(C_k[P .== r], quantiles) for r in 1:m_j ]
    return hcat(Q...)
end


"""
    partitioning(C::AbstractMatrix, π::Vector{Int})

Calculate branching matrices and indices for a matrix of features C and a
partitioning vector π. The matrix C is of size (n,p) where n is the number of
scalar features (per observation) and p is the number observations/samples.

The method returns a vector (or list) of branching matrices Qs, a matrix
of multi-indices Alpha, and the corresponding partition index R. Qs is of
length n, Alpha is of size (n,p) and R is of length p.
"""
function partitioning(C::AbstractMatrix, π::Vector{Int})
    @assert size(C)[1] == length(π)
    @assert all(π .> 0)
    Qs = AbstractMatrix[]
    Alpha = zeros(Int, 0, size(C)[2])
    for i in 1:length(π)
        Qi = branching_matrix(π[begin:i], Alpha, C[i,:])
        Ai = [ sub_index(C[i,j], π[begin:i], Alpha[:,j], Qi) for j=1:size(C)[2] ]
        # update...
        Alpha = vcat(Alpha, Ai')
        push!(Qs, Qi)
    end
    R = [ partition_index(π, Alpha[:,j]) for j = 1:size(C)[2] ]
    return (Qs, Alpha, R)
end


"""
A PiecewiseRegression holds the information on the partitioning of the training
data set and a list of regressions.
The information on the partitioning is encoded in the partitioning vector π,
the list of branching matrices Qs and the list of polynomial regressions.
"""
struct PiecewiseRegression
    π::Vector{Int}
    Qs::Vector{AbstractMatrix}
    regs::Vector{PolynomialRegression}
end

"""
    piecewise_regression(
        C::AbstractMatrix,
        O::AbstractVector,
        max_degree::Int,
        π::Vector{Int},
        )

Create a PiecewiseRegression from a matrix of features (or controls) C, a vector
of labels (or observations) O, a maximum polynomial degree (max_degree), and a
partitioning vector π.

C is of size (n,p), O is of length p, max_degree should be 2 (or 3) and π is
of length n. The entries of π should be between 2 and 4; depending on the number
of observations p and the number of dimensions n.
"""
function piecewise_regression(
    C::AbstractMatrix,
    O::AbstractVector,
    max_degree::Int,
    π::Vector{Int},
    )
    #
    @assert size(C) == (length(π), length(O))
    @assert all(π .> 0)
    (Qs, Alpha, R) = partitioning(C,π)
    regs = PolynomialRegression[]
    for r in 1:prod(π)
        reg = polynomial_regression(C[:,R .== r], O[R .== r], max_degree)
        push!(regs, reg)
    end
    return PiecewiseRegression(π, Qs, regs)
end

"""
    predict(reg::PiecewiseRegression, C::Matrix)

Use a calibrates piecewise polynomial regression to predict function values.
Input is a matrix of controls C of size (n,p). Result is a vector
of size (p,).
"""
function predict(reg::PiecewiseRegression, C::Matrix)
    Alpha = hcat((multi_index(C[:,j], reg.π, reg.Qs) for j in 1:size(C)[2])...)
    R = [ partition_index(reg.π, Alpha[:,j]) for j = 1:size(C)[2] ]
    p = zeros(size(C)[2])
    for r in 1:prod(reg.π)
        p[R .== r] = predict(reg.regs[r], C[:,R .== r])
    end
    return p
end
