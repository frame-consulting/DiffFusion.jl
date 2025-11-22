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
        x::AbstractVector,
        m::Module = ForwardDiff,
        )

Calculate the function value and gradient of a function.
"""
function _function_value_and_gradient(
    f::Function,
    x::AbstractVector,
    m::Module = ForwardDiff,
    )
    #
    if m == ForwardDiff
        v = f(x)
        g = ForwardDiff.gradient(f, x)
        return (v, g)
    end
    if m == Zygote
        (v, g) = Zygote.withgradient(f, x)
        @assert length(g) == 1
        return (v, g[1])
    end
    if m == FiniteDifferences
        v = f(x)
        m = FiniteDifferences.central_fdm(3, 1)
        g = FiniteDifferences.grad(m, f, x)
        return (v, g[1])
    end
    error("Unknown module " * string(m) * ".")
end


"""
    _function_value_and_gradient(
        f::Function,
        x::Dict,
        )

Calculate the function value and gradient of a function using Zygote.
"""
function _function_value_and_gradient(
    f::Function,
    x::Dict,
    )
    # only Zygote supports Dict
    (v, g) = Zygote.withgradient(f, x)
    @assert length(g) == 1
    return (v, g[1])
end


"""
    _function_value_and_gradient(
        f::Function,
        x::AbstractVector,
        adType::DifferentiationInterface.AbstractADType,
        )

Calculate the function value and gradient of a function using DifferentiationInterface.
"""
function _function_value_and_gradient(
    f::Function,
    x::AbstractVector,
    adType::DifferentiationInterface.AbstractADType,
    )
    #
    return value_and_gradient(f, adType, x)
end
