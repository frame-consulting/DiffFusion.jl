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
        m::Module = Zygote,
        )

Calculate the function value and gradient of a function.
"""
function _function_value_and_gradient(
    f::Function,
    x::Any,
    m::Module = Zygote,
    )
    #
    if m == Zygote
        (v, g) = withgradient(f, x)
        @assert length(g) == 1
        return (v, g[1])
    end
    if m == ForwardDiff
        v = f(x)
        g = ForwardDiff.gradient(f, x)
        return (v, g)
    end
    error("Unknown module " * string(m) * ".")
end
