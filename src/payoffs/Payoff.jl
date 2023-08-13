
"""
    abstract type Payoff end

A `Payoff` is a random variable *X* in our stochastic model.

It represents a market object that can be evaluated in conjunction with a given path.

We are interested in realisations of a payoff *at* a given path, i.e. *X(omega)*. Moreover,
for risk-neutral valuation we are also interested in *discounted* payoffs *at* a given path.

We implement a `Payoff` as a root of a computational graph. The nodes of the computational
graph are itself `Payoff` objects which represent mathematical operations or use the path *omega*
to determine its realisations.
"""
abstract type Payoff end

"""
    obs_time(p::Payoff)

A `Payoff` is typically observed at a particular time. In that sense, a `Payoff` is an
``F_t``-measurable random variable.

The observation time represents the time, after which the payoff *is known*.
"""
function obs_time(p::Payoff)
    error("Payoff needs to implement obs_time method.")
end

"""
    obs_times(p::Payoff)

A payoff is typically linked to other payoffs and forms a DAG. This function returns all
observation times associated with a given payoff.

This functionality is required to determine relevant simulation grid points.
"""
function obs_times(p::Payoff)
    error("Payoff needs to implement obs_times method.")
end

"""
    at(p::Payoff, path::AbstractPath)

Evaluate a `Payoff` at a given `path`, *X(omega)*.

Depending on the functionality associated with the `path`, this function typically
returns a vector of realisations.

This function is invoked when using call operator on a `Payoff`,

    (p::Payoff)(path::AbstractPath) = at(p::Payoff, path::AbstractPath)

"""
function at(p::Payoff, path::AbstractPath)
    error("Payoff needs to implement at method.")
end

"""
    (p::Payoff)(path::AbstractPath)

Syntactic sugar for payoff evaluation
"""
(p::Payoff)(path::AbstractPath) = at(p::Payoff, path::AbstractPath)

"""
    abstract type Leaf <: Payoff end

A Leaf is a particular Payoff which has no outgoing links to other Payoff objects. A Leaf
typically uses the path to determine its realisations.

We assume that a Leaf has a field obs_time.
"""
abstract type Leaf <: Payoff end

"""
    obs_time(p::Leaf)

Return the observation time for a Leaf object.
"""
obs_time(p::Leaf) = p.obs_time

"""
    obs_times(p::Leaf)

Derive the set of observation times from the single observation time of the Leaf object.
"""
obs_times(p::Leaf) = Set(obs_time(p))


"""
    abstract type UnaryNode <: Payoff end

A UnaryNode is a particular Payoff which has exactly one outgoing link to another Payoff
object.

We assume that the reference to the outgoing Payoff object is a field denoted *x*.

A UnaryNode is typically a decorator of the linked Payoff.
"""
abstract type UnaryNode <: Payoff end

"""
    obs_time(p::UnaryNode)

Return the observation time of the linked payoff.
"""
obs_time(p::UnaryNode) = obs_time(p.x)

"""
    obs_times(p::UnaryNode)

Return all observation times of the linked payoff.
"""
obs_times(p::UnaryNode) = obs_times(p.x)


"""
    abstract type BinaryNode <: Payoff end

A BinaryNode is a particular Payoff which has exactly two outgoing links to other
Payoff objects.

We assume that the references to the outgoing Payoff objects are fields denoted
*x* and *y*.

A BinaryNode is typically a mathematical operation.
"""
abstract type BinaryNode <: Payoff end

"""
    obs_time(p::BinaryNode)

Derive the observation time from linked payoffs.
"""
obs_time(p::BinaryNode) = max(obs_time(p.x), obs_time(p.y))

"""
    obs_times(p::BinaryNode)

Derive all observation times from linked payoff.
"""
obs_times(p::BinaryNode) = union(obs_times(p.x), obs_times(p.y))
