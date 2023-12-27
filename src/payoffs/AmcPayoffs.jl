
"""
    struct AmcPayoffLinks
        obs_time::ModelTime
        x::AbstractVector
        y::AbstractVector
        z::AbstractVector
        curve_key::String
    end

An AmcPayoffLinks object holds common data fields for an American Monte Carlo
(AMC) payoff.

Here, `obs_time` is the observation time of the AMC payoff and `x`, `y`, `z` are related
`Payoff` vectors. The elements of `x` and `y` represent random variables with observation
times after `obs_time`. The elements of `z` represent random variables with observation
time (at or) before `obs_time`. `z` is the vector of regression variables.

The parameter `curve_key` is used to specify a discount curve for numeraire price
calculation.

We calculate ``X`` as the sum of discounted payoff values of `x` and ``Y`` as the sum of
discounted payoff values of `y`. ``Z = [ Z_1, Z_2, ... ]`` represent the (undiscounted)
values of the regression variables from the payoff vector `z`.

Then we estimate the trigger variable

``
T = E[ X - Y | Z_1, Z_2, ... ]
``

An actual AMC payoff uses ``X``, ``Y``, and ``T`` to calculate its values.
"""
struct AmcPayoffLinks
    obs_time::ModelTime
    x::AbstractVector
    y::AbstractVector
    z::AbstractVector
    curve_key::String
end

"""
    mutable struct AmcPayoffRegression
        path::Union{AbstractPath, Nothing}
        make_regression::Union{Function, Nothing}
        regression::Any
    end

AmcPayoffRegression holds the common data fields to regression and regression
calibration for AMC payoffs. These data fields are supposed to be updated subsequent
creation of the object. As a consequence, AmcPayoffRegression is declared mutable.

The element `path` is a Monte Carlo path. This element is typically linked to a
simulation and a context mapping.

`make_regression` is a function/functor with signature

    make_regression(C::AbstractMatrix, O::AbstractVector) -> obj.

This function is typically a lambda for *polynomial_regression* (or similar) where
parameters like maximum polynomial degree are fixed.

The result of `make_regression` is stored in the `regression` field. For the result
object `regression` we assume that a method

    predict(regression, C)

is defined. The method `predict` is supposed to return a prediction for a matrix
of controls `C`. See `PolynomialRegression` as an example.
"""
mutable struct AmcPayoffRegression
    path::Union{AbstractPath, Nothing}
    make_regression::Union{Function, Nothing}
    regression::Any
end


"""
    calibrate_regression(links::AmcPayoffLinks, regr::AmcPayoffRegression)

Calibrate the regression for an AMC payoff.
"""
function calibrate_regression(links::AmcPayoffLinks, regr::AmcPayoffRegression)
    if length(links.z) > 0 && !isnothing(regr.path) && !isnothing(regr.make_regression)
        T = zeros(length(regr.path))
        for x in links.x
            T += at(x, regr.path) ./ numeraire(regr.path, obs_time(x), links.curve_key)
        end
        for y in links.y
            T -= at(y, regr.path) ./ numeraire(regr.path, obs_time(y), links.curve_key)
        end
        T = T .* numeraire(regr.path, links.obs_time, links.curve_key)
        Z = hcat([ z(regr.path) for z in links.z ]...)'
        #
        return regr.make_regression(Z, T)
    end
    return nothing  # cannot calibrate
end

"""
    at(links::AmcPayoffLinks, regr::AmcPayoffRegression, path::AbstractPath)

Calculate the common components of AMC payoffs for a given valuation path.
"""
function at(links::AmcPayoffLinks, regr::AmcPayoffRegression, path::AbstractPath)
    if isnothing(regr.regression)  # try to calibrate
        regr.regression = calibrate_regression(links, regr)
    end
    if length(links.z) > 0 && !isnothing(regr.regression)
        # use regression to calculate payoff
        Z = hcat([ z(path) for z in links.z ]...)'
        T = predict(regr.regression, Z)
        # we delegate X, Y calculation to the payoff
        return (nothing, nothing, T)
    end
    # we look into the future; this leads to overestimation of American options.
    N = numeraire(path, links.obs_time, links.curve_key)
    X = zeros(length(path))
    for x in links.x
        X += at(x, path) ./ numeraire(path, obs_time(x), links.curve_key)
    end
    X = X .* N
    Y = zeros(length(path))
    for y in links.y
        Y += at(y, path) ./ numeraire(path, obs_time(y), links.curve_key)
    end
    Y = Y .* N
    T = X .- Y
    return (X, Y, T)
end

"""
    string(links::AmcPayoffLinks)

Formatted (and shortened) output for AMC payoff links.
"""
function string(links::AmcPayoffLinks)
    s = @sprintf("(%.2f, ", links.obs_time)
    # x
    s *= "["
    for x in links.x
        s *= string(x) * ", "
    end
    if s[end] == ' '
        s = s[begin:end-2]
    end
    s *= "], "
    # y
    s *= "["
    for y in links.y
        s *= string(y) * ", "
    end
    if s[end] == ' '
        s = s[begin:end-2]
    end
    s *= "], "
    # z
    s *= "["
    for z in links.z
        s *= string(z) * ", "
    end
    if s[end] == ' '
        s = s[begin:end-2]
    end
    s *= "])"
    return s
end


"""
    abstract type AmcPayoff <: Payoff end

AmcPayoff is used to implement common methods for AMC payoffs. Concrete AMC
payoffs are assumed to hold a fields `links::AmcPayoffLinks` and
`regr::AmcPayoffRegression`.

An AMC payoff is special and does not fit into the structure of unary/binary
nodes. Instead, we have several edges to other payoffs with observation times
before (x and y) and after (z) its own observation time.
"""
abstract type AmcPayoff <: Payoff end

"""
    obs_time(p::AmcPayoff)

Return the AMC payoff observation time
"""
obs_time(p::AmcPayoff) = p.links.obs_time

"""
    obs_times(p::AmcPayoff)

Return observation times of all referenced payoffs.
"""
function obs_times(p::AmcPayoff)
    times = Set(obs_time(p))
    for x in p.links.x
        times = union(times, obs_times(x))
    end
    for y in p.links.y
        times = union(times, obs_times(y))
    end
    for z in p.links.z
        times = union(times, obs_times(z))
    end
    return times
end


"""
    has_amc_payoff(p::AmcPayoff)

Determine whether a payoff is or contains an AMC payoff.

AMC payoffs require special treatment e.g. for sensitivity calculation.
"""
has_amc_payoff(p::AmcPayoff) = true


"""
    has_amc_payoff(p::UnaryNode)

Determine whether a payoff is or contains an AMC payoff.
"""
has_amc_payoff(p::UnaryNode) = has_amc_payoff(p.x)

"""
    has_amc_payoff(p::BinaryNode)

Determine whether a payoff is or contains an AMC payoff.
"""
has_amc_payoff(p::BinaryNode) = has_amc_payoff(p.x) || has_amc_payoff(p.y)

"""
    has_amc_payoff(p::Union{Leaf, CompoundedRate, Optionlet, Swaption})

Determine whether a payoff is or contains an AMC payoff.
"""
has_amc_payoff(p::Union{Leaf, CompoundedRate, Optionlet, Swaption}) = false

"""
    has_amc_payoff(p::Payoff)

Determine whether a payoff is or contains an AMC payoff.
"""
has_amc_payoff(p::Payoff) = begin
    error("Payoff " * string(typeof(p)) *  " needs to implement has_amc_payoff method.")
    return false
end

"""
    has_amc_payoff(payoffs::AbstractVector)

Determine whether any payoff is or contains an AMC payoff.
"""
has_amc_payoff(payoffs::AbstractVector) = begin
    return any([ has_amc_payoff(p) for p in payoffs ])
end


"""
    reset_regression!(
        p::AmcPayoff,
        path::Union{AbstractPath, Nothing} = nothing,
        make_regression::Union{Function, Nothing}  = nothing,
        )

Reset the regression properties for an AMC payoffs.
    
This method is used to allow setting and updating AMC regression after
payoff creation.
"""
function reset_regression!(
    p::AmcPayoff,
    path::Union{AbstractPath, Nothing} = nothing,
    make_regression::Union{Function, Nothing}  = nothing,
    )
    p.regr.regression = nothing  # this triggers re-calibration
    if !isnothing(path)
        p.regr.path = path
    end
    if !isnothing(make_regression)
        p.regr.make_regression = make_regression
    end
end

"""
    reset_regression!(
        p::UnaryNode,
        path::Union{AbstractPath, Nothing} = nothing,
        make_regression::Union{Function, Nothing}  = nothing,
        )

Delegate resetting the regression properties to child payoff.
"""
function reset_regression!(
    p::UnaryNode,
    path::Union{AbstractPath, Nothing} = nothing,
    make_regression::Union{Function, Nothing}  = nothing,
    )
    reset_regression!(p.x, path, make_regression)
end

"""
    reset_regression!(
        p::BinaryNode,
        path::Union{AbstractPath, Nothing} = nothing,
        make_regression::Union{Function, Nothing}  = nothing,
        )

Delegate resetting the regression properties to child payoffs.
"""
function reset_regression!(
    p::BinaryNode,
    path::Union{AbstractPath, Nothing} = nothing,
    make_regression::Union{Function, Nothing}  = nothing,
    )
    reset_regression!(p.x, path, make_regression)
    reset_regression!(p.y, path, make_regression)
end

"""
    reset_regression!(
        p::Union{Leaf, CompoundedRate, Optionlet, Swaption},
        path::Union{AbstractPath, Nothing} = nothing,
        make_regression::Union{Function, Nothing}  = nothing,
        )

Ignore resetting the regression properties for Leaf and similar payoffs.

Note that some rates payoffs and rates options are no Leafs.
"""
function reset_regression!(
    p::Union{Leaf, CompoundedRate, Optionlet, Swaption},
    path::Union{AbstractPath, Nothing} = nothing,
    make_regression::Union{Function, Nothing}  = nothing,
    )
end

"""
    reset_regression!(
        p::Payoff,
        path::Union{AbstractPath, Nothing} = nothing,
        make_regression::Union{Function, Nothing}  = nothing,
        )

Throw an error if reset_regression! is not implemented for
concrete payoff.
"""
function reset_regression!(
    p::Payoff,
    path::Union{AbstractPath, Nothing} = nothing,
    make_regression::Union{Function, Nothing}  = nothing,
    )
    error("Payoff " * string(typeof(p)) *  " needs to implement reset_regression! method.")
end


"""
    _is_larger_zero(T::AbstractArray)

Implement a differentiable version of the indicator (T>0).
"""
function _is_larger_zero(T::AbstractArray)
    # return 1.0 * (T .> 0.0)
    scaling = 1.0e+8
    return 0.5 .+ 0.5 .* tanh.(scaling .* T)
end

"""
    struct AmcMax <: AmcPayoff
        links::AmcPayoffLinks
        regr::AmcPayoffRegression
    end

An AmcMax payoff is used to model long call rights.

It calculates the expectation of maximum of (sum of) discounted payoffs `x` and (sum of)
discounted payoffs `y`. Expectation is calculated conditional on information at `obs_time`.
This is approximated by regression variable payoffs `z`.
"""
struct AmcMax <: AmcPayoff
    links::AmcPayoffLinks
    regr::AmcPayoffRegression
end

"""
    AmcMax(
        obs_time::ModelTime,
        x::AbstractVector,
        y::AbstractVector,
        z::AbstractVector,
        path::Union{AbstractPath, Nothing},
        make_regression::Union{Function, Nothing},
        curve_key::String,
        )

Create an AmcMax payoff.
"""
function AmcMax(
    obs_time::ModelTime,
    x::AbstractVector,
    y::AbstractVector,
    z::AbstractVector,
    path::Union{AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
    curve_key::String,
    )
    return AmcMax(
        AmcPayoffLinks(obs_time, x, y, z, curve_key),
        AmcPayoffRegression(path, make_regression, nothing),
    )
end

"""
    at(p::AmcMax, path::AbstractPath)

Evaluate an AmcMax payoff at a given path.
"""
function at(p::AmcMax, path::AbstractPath)
    (X, Y, T) = at(p.links, p.regr, path)
    if isnothing(X) || isnothing(Y)
        # this is the typical case when we use regression
        N = numeraire(path, p.links.obs_time, p.links.curve_key)
        X = zeros(length(path))
        for x in p.links.x
            X += at(x, path) ./ numeraire(path, obs_time(x), p.links.curve_key)
        end
        X = X .* N
        Y = zeros(length(path))
        for y in p.links.y
            Y += at(y, path) ./ numeraire(path, obs_time(y), p.links.curve_key)
        end
        Y = Y .* N
    end
    use_X = _is_larger_zero(T)
    return use_X .* X .+ (1.0 .- use_X) .* Y
end

"""
    string(p::AmcMax)

Formatted (and shortened) output for AmcMax payoff.
"""
function string(p::AmcMax)
    return "AmcMax" * string(p.links)
end


"""
    struct AmcMin <: AmcPayoff
        links::AmcPayoffLinks
        regr::AmcPayoffRegression
    end

An AmcMin payoff is used to model short call rights.

It calculates the expectation of minimum of (sum of) discounted payoffs `x` and (sum of)
discounted payoffs `y`. Expectation is calculated conditional on information at `obs_time`.
This is approximated by regression variable payoffs `z`.
"""
struct AmcMin <: AmcPayoff
    links::AmcPayoffLinks
    regr::AmcPayoffRegression
end

"""
    AmcMin(
        obs_time::ModelTime,
        x::AbstractVector,
        y::AbstractVector,
        z::AbstractVector,
        path::Union{AbstractPath, Nothing},
        make_regression::Union{Function, Nothing},
        curve_key::String,
        )

Create an AmcMin payoff.
"""
function AmcMin(
    obs_time::ModelTime,
    x::AbstractVector,
    y::AbstractVector,
    z::AbstractVector,
    path::Union{AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
    curve_key::String,
    )
    return AmcMin(
        AmcPayoffLinks(obs_time, x, y, z, curve_key),
        AmcPayoffRegression(path, make_regression, nothing),
    )
end

"""
    at(p::AmcMin, path::AbstractPath)

Evaluate an AmcMin payoff at a given path.
"""
function at(p::AmcMin, path::AbstractPath)
    (X, Y, T) = at(p.links, p.regr, path)
    if isnothing(X) || isnothing(Y)
        # this is the typical case when we use regression
        N = numeraire(path, p.links.obs_time, p.links.curve_key)
        X = zeros(length(path))
        for x in p.links.x
            X += at(x, path) ./ numeraire(path, obs_time(x), p.links.curve_key)
        end
        X = X .* N
        Y = zeros(length(path))
        for y in p.links.y
            Y += at(y, path) ./ numeraire(path, obs_time(y), p.links.curve_key)
        end
        Y = Y .* N
    end
    use_Y = _is_larger_zero(T)
    return (1.0 .- use_Y) .* X .+ use_Y .* Y
end

"""
    string(p::AmcMin)

Formatted (and shortened) output for AmcMin payoff.
"""
function string(p::AmcMin)
    return "AmcMin" * string(p.links)
end


"""
    struct AmcOne <: AmcPayoff
        links::AmcPayoffLinks
        regr::AmcPayoffRegression
    end

An AmcOne payoff is used to model the indicator variable ``1_{(X > Y)}``.

It calculates the expectation of maximum of (sum of) discounted payoffs `x` and (sum of)
discounted payoffs `y`. Expectation is calculated conditional on information at `obs_time`.
This is approximated by regression variable payoffs `z`.
"""
struct AmcOne <: AmcPayoff
    links::AmcPayoffLinks
    regr::AmcPayoffRegression
end

"""
    AmcOne(
        obs_time::ModelTime,
        x::AbstractVector,
        y::AbstractVector,
        z::AbstractVector,
        path::Union{AbstractPath, Nothing},
        make_regression::Union{Function, Nothing},
        curve_key::String,
        )

Create an AmcOne payoff.
"""
function AmcOne(
    obs_time::ModelTime,
    x::AbstractVector,
    y::AbstractVector,
    z::AbstractVector,
    path::Union{AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
    curve_key::String,
    )
    return AmcOne(
        AmcPayoffLinks(obs_time, x, y, z, curve_key),
        AmcPayoffRegression(path, make_regression, nothing),
    )
end

"""
    at(p::AmcOne, path::AbstractPath)

Evaluate an AmcOne payoff at a given path.
"""
function at(p::AmcOne, path::AbstractPath)
    (X, Y, T) = at(p.links, p.regr, path)
    return _is_larger_zero(T)
end

"""
    string(p::AmcOne)

Formatted (and shortened) output for AmcOne payoff.
"""
function string(p::AmcOne)
    return "AmcOne" * string(p.links)
end


"""
    struct AmcSum <: AmcPayoff
        links::AmcPayoffLinks
        regr::AmcPayoffRegression
    end

An `AmcSum` payoff is used to model general conditional expectations

``B(t) E[ X(T)/B(T) | Z(t) ]``

`AmcSum` payoffs are typically used to calculate future model prices in
exposure simulation applications. 
"""
struct AmcSum <: AmcPayoff
    links::AmcPayoffLinks
    regr::AmcPayoffRegression
end

"""
    AmcSum(
        obs_time::ModelTime,
        x::AbstractVector,
        z::AbstractVector,
        path::Union{AbstractPath, Nothing},
        make_regression::Union{Function, Nothing},
        curve_key::String,
        )

Create an AmcSum payoff.
"""
function AmcSum(
    obs_time::ModelTime,
    x::AbstractVector,
    z::AbstractVector,
    path::Union{AbstractPath, Nothing},
    make_regression::Union{Function, Nothing},
    curve_key::String,
    )
    return AmcSum(
        AmcPayoffLinks(obs_time, x, [], z, curve_key),
        AmcPayoffRegression(path, make_regression, nothing),
    )
end

"""
    at(p::AmcSum, path::AbstractPath)

Evaluate an AmcSum payoff at a given path.
"""
function at(p::AmcSum, path::AbstractPath)
    (X, Y, T) = at(p.links, p.regr, path)
    return T
end

"""
    string(p::AmcSum)

Formatted (and shortened) output for AmcSum payoff.
"""
function string(p::AmcSum)
    return "AmcSum" * string(p.links)
end
