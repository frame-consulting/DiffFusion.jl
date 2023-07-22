module DiffFusion

using Interpolations
using LinearAlgebra
using ProgressBars
using Random
using QuadGK
using SparseArrays


"""
A type alias for variables representing time.
"""
ModelTime = Number

"""
A type alias for variables representing modelled quantities.
"""
ModelValue = Number

include("termstructures/Termstructures.jl")
include("termstructures/correlation/CorrelationHolder.jl")
include("termstructures/parameter/ParameterTermstructures.jl")
include("termstructures/rates/YieldTermstructures.jl")
include("termstructures/volatility/VolatilityTermstructures.jl")

include("models/Model.jl")
include("models/asset/AssetModel.jl")
include("models/asset/LognormalAssetModel.jl")
include("models/rates/SeparableHjmModel.jl")
include("models/rates/GaussianHjmModel.jl")

include("utils/Integrations.jl")
include("utils/InterpolationMethods.jl")



end
