"""
This file includes common interfaces and wrappers for mathematical
derivative calculations via Automatic Differentiation tools that are used
in the package.

The centralisation of these routines should simplify replacing and fine-
tuning AD routines.
"""

"""
    _function_value_and_gradient(
        f::Function,
        x::Any,
        m::Module = ForwardDiff,
        )

Calculate the function value and gradient of a function.
"""
function _function_value_and_gradient(
    f::Function,
    x::Any,
    m::Module = ForwardDiff,
    )
    #
    if m == ForwardDiff
        v = f(x)
        g = ForwardDiff.gradient(f, x)
        return (v, g)
    end
    if m == Zygote
        (v, g) = withgradient(f, x)
        @assert length(g) == 1
        return (v, g[1])
    end
    if m == FiniteDifferences
        v = f(x)
        m = central_fdm(3, 1)
        g = grad(m, f, x)
        return (v, g[1])
    end
    if m == ADOLC
        v = f(x)
        g = derivative(f, x, :jac)
        return v, g
    end
    error("Unknown module " * string(m) * ".")
end
