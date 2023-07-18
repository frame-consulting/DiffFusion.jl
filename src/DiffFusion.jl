module DiffFusion

using Interpolations
using LinearAlgebra
using ProgressBars
using Random


"""
A type alias for variables representing time.
"""
ModelTime = Number

"""
A type alias for variables representing modelled quantities.
"""
ModelValue = Number

include("termstructures/Termstructures.jl")
include("termstructures/parameter/ParameterTermstructures.jl")
include("termstructures/rates/YieldTermstructures.jl")
include("termstructures/volatility/VolatilityTermstructures.jl")

include("utils/InterpolationMethods.jl")


end
