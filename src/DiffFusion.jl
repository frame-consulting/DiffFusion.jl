module DiffFusion

using Distributions
using Interpolations
using LinearAlgebra
using ProgressBars
using Random
using QuadGK
using Sobol
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
include("models/hybrid/CompositeModel.jl")
include("models/hybrid/SimpleModel.jl")
include("models/rates/SeparableHjmModel.jl")
include("models/rates/GaussianHjmModel.jl")
include("models/futures/MarkovFutureModels.jl")

include("simulations/RandomNumbers.jl")
include("simulations/Simulation.jl")

include("utils/Integrations.jl")
include("utils/InterpolationMethods.jl")



end
