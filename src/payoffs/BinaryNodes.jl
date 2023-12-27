
"""
    struct Add <: BinaryNode
        x::Payoff
        y::Payoff
    end

Addition of payoffs.
"""
struct Add <: BinaryNode
    x::Payoff
    y::Payoff
end

"""
    struct Sub <: BinaryNode
        x::Payoff
        y::Payoff
    end

Subtraction of payoffs.
"""
struct Sub <: BinaryNode
    x::Payoff
    y::Payoff
end

"""
    struct Mul <: BinaryNode
        x::Payoff
        y::Payoff
    end

Multiplication of payoffs.
"""
struct Mul <: BinaryNode
    x::Payoff
    y::Payoff
end

"""
    struct Div <: BinaryNode
        x::Payoff
        y::Payoff
    end

Division of payoffs.
"""
struct Div <: BinaryNode
    x::Payoff
    y::Payoff
end

"""
    struct Max <: BinaryNode
        x::Payoff
        y::Payoff
    end

Path-wise maximum
"""
struct Max <: BinaryNode
    x::Payoff
    y::Payoff
end

"""
    struct Min <: BinaryNode
        x::Payoff
        y::Payoff
    end

Path-wise minimum
"""
struct Min <: BinaryNode
    x::Payoff
    y::Payoff
end

"""
    struct Logical <: BinaryNode
        x::Payoff
        y::Payoff
        op::String
    end

Logical operations
"""
struct Logical <: BinaryNode
    x::Payoff
    y::Payoff
    op::String
end

"""
## Implementations
"""

"Addition."
at(p::Add, path::AbstractPath) = at(p.x, path) .+ at(p.y, path)

"Subtraction."
at(p::Sub, path::AbstractPath) = at(p.x, path) .- at(p.y, path)

"Multiplication."
at(p::Mul, path::AbstractPath) = at(p.x, path) .* at(p.y, path)

"Division."
at(p::Div, path::AbstractPath) = at(p.x, path) ./ at(p.y, path)

"Maximum"
at(p::Max, path::AbstractPath) = max.(at(p.x, path), at(p.y, path))

"Minimum"
at(p::Min, path::AbstractPath) = min.(at(p.x, path), at(p.y, path))

"Logical"
function at(p::Logical, path::AbstractPath)
    if p.op == "<"
        return at(p.x, path) .< at(p.y, path)
    elseif p.op == "<="
        return at(p.x, path) .<= at(p.y, path)
    elseif p.op == "=="
        return at(p.x, path) .== at(p.y, path)
    elseif p.op == "!="
        return at(p.x, path) .!= at(p.y, path)
    elseif p.op == ">="
        return at(p.x, path) .>= at(p.y, path)
    elseif p.op == ">"
        return at(p.x, path) .> at(p.y, path)
    end
    error("Unknown logical operation.")
end


"""
## String output
"""

"Formatted addition."
string(p::Add) = @sprintf("(%s + %s)", string(p.x), string(p.y))

"Formatted subtraction."
string(p::Sub) = @sprintf("(%s - %s)", string(p.x), string(p.y))

"Formatted multiplication."
string(p::Mul) = @sprintf("%s * %s", string(p.x), string(p.y))

"Formatted division."
string(p::Div) = @sprintf("(%s / %s)", string(p.x), string(p.y))

"Formatted maximum."
string(p::Max) = @sprintf("Max(%s, %s)", string(p.x), string(p.y))

"Formatted minimum."
string(p::Min) = @sprintf("Min(%s, %s)", string(p.x), string(p.y))

"Formatted logical."
string(p::Logical) = @sprintf("(%s %s %s)", string(p.x), p.op, string(p.y))


"""
## Operator notation
"""

import Base.+ 
(+)(x::Payoff,y::Payoff) = Add(x,y)
(+)(x::Payoff,y) = Add(x,Fixed(y))
(+)(x,y::Payoff) = Add(Fixed(x),y)

import Base.-
(-)(x::Payoff,y::Payoff) = Sub(x,y)
(-)(x::Payoff,y) = Sub(x,Fixed(y))
(-)(x,y::Payoff) = Sub(Fixed(x),y)

import Base.*
(*)(x::Payoff,y::Payoff) = Mul(x,y)
(*)(x::Payoff,y) = Mul(x,Fixed(y))
(*)(x,y::Payoff) = Mul(Fixed(x),y)

import Base./
(/)(x::Payoff,y::Payoff) = Div(x,y)
(/)(x::Payoff,y) = Div(x,Fixed(y))
(/)(x,y::Payoff) = Div(Fixed(x),y)

#import Base.%
#(%)(x::Payoff,t) = Pay(x,t)

import Base.<
(<)(x::Payoff,y::Payoff) = Logical(x,y,"<")
(<)(x::Payoff,y) = Logical(x,Fixed(y),"<")
(<)(x,y::Payoff) = Logical(Fixed(x),y,"<")

import Base.<=
(<=)(x::Payoff,y::Payoff) = Logical(x,y,"<=")
(<=)(x::Payoff,y) = Logical(x,Fixed(y),"<=")
(<=)(x,y::Payoff) = Logical(Fixed(x),y,"<=")

import Base.==
(==)(x::Payoff,y::Payoff) = Logical(x,y,"==")
(==)(x::Payoff,y) = Logical(x,Fixed(y),"==")
(==)(x,y::Payoff) = Logical(Fixed(x),y,"==")

import Base.!=
(!=)(x::Payoff,y::Payoff) = Logical(x,y,"!=")
(!=)(x::Payoff,y) = Logical(x,Fixed(y),"!=")
(!=)(x,y::Payoff) = Logical(Fixed(x),y,"!=")

import Base.>=
(>=)(x::Payoff,y::Payoff) = Logical(x,y,">=")
(>=)(x::Payoff,y) = Logical(x,Fixed(y),">=")
(>=)(x,y::Payoff) = Logical(Fixed(x),y,">=")

import Base.>
(>)(x::Payoff,y::Payoff) = Logical(x,y,">")
(>)(x::Payoff,y) = Logical(x,Fixed(y),">")
(>)(x,y::Payoff) = Logical(Fixed(x),y,">")


Max(x::Payoff,y) = Max(x,Fixed(y))
Max(x,y::Payoff) = Max(Fixed(x),y)
Min(x::Payoff,y) = Min(x,Fixed(y))
Min(x,y::Payoff) = Min(Fixed(x),y)
