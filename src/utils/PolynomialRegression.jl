
"""
    multi_index(n::Int, k::Int)

Calculate an `Int` matrix as `Vector{Vector{Int}}` of size (m,n) where each row
represents an n-dimensional multi-index α with degree |α| < k.
"""
function multi_index(n::Int, k::Int)
    if n == 1
        return [ [i] for i in 0:k-1 ]
    end
    vec = Vector{Vector{Int}}[]
    for i in 0:k-1
        for s in multi_index(n-1, k-i)
            elm = vcat(s, [i])
            vec = vcat(vec, [elm])
        end
    end
    return vec
end


"""
    monomials(C::AbstractMatrix, V::AbstractMatrix)

Calculate monomials M of size (m,p) for a matrix of controls C of
size (n,p) and a matrix V of multi-indices α. V is of size (m,n).
"""
function monomials(C::AbstractMatrix, V::AbstractMatrix)
    row(i) = begin
        m = ones(size(C)[2])
        for j in 1:size(V)[2]
            m = m .* (C[j,:].^V[i,j])
        end
        return reshape(m, (1,:))
    end
    M = vcat([ row(i) for i in 1:size(V)[1] ]...)
    return M
end


"""
    struct PolynomialRegression
        V::Matrix{Int}
        beta::AbstractVector
    end

A `PolynomialRegression` holds allows to predict values of a multi-variate
function. The polynomial degrees are encoded in the multi-index matrix *V*.
The polynomial coefficients are stored in the vector *beta*.
"""
struct PolynomialRegression
    V::Matrix{Int}
    beta::AbstractVector
end

"""
    polynomial_regression(
        C::AbstractMatrix,
        O::AbstractVector,
        max_degree::Int,
        )

Calibrate a `PolynomialRegression` object from a matrix of controls C of
size (n,p) and a vector of observations O of size (p,). The maximum
polynomial degree is given by max_degree. 
"""
function polynomial_regression(
    C::AbstractMatrix,
    O::AbstractVector,
    max_degree::Int,
    )
    @assert size(C)[1] > 0
    @assert size(C)[2] == length(O)
    V = multi_index(size(C)[1], max_degree + 1)
    V = Matrix(reduce(hcat, V)')
    M = monomials(C, V)
    @assert size(M)[2] == length(O)
    beta = M' \ O  # Solve via linear least squares.
    return PolynomialRegression(V, beta)
end

"""
    predict(reg::PolynomialRegression, C::AbstractMatrix)

Use a calibrated polynomial regression to predict function values.
Input is a matrix of controls C of size (n,p). Result is a vector
of size (p,).
"""
function predict(reg::PolynomialRegression, C::AbstractMatrix)
    M = monomials(C, reg.V)
    return M' * reg.beta
end
