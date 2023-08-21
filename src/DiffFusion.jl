module DiffFusion

using Distributions
using Interpolations
using LinearAlgebra
using Printf
using ProgressBars
using QuadGK
using Random
using Sobol
using SparseArrays

import Base.length
import Base.string

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

include("paths/AbstractPath.jl")
include("paths/Context.jl")
include("paths/Path.jl")
include("paths/PathMethods.jl")

include("payoffs/Payoff.jl")
include("payoffs/Leafs.jl")
include("payoffs/UnaryNodes.jl")
include("payoffs/BinaryNodes.jl")
include("payoffs/RatesPayoffs.jl")

include("products/Cashflows.jl")
include("products/RatesCoupons.jl")
include("products/CashFlowLeg.jl")
include("products/MtMCashFlowLeg.jl")
include("products/CashAndAssetLegs.jl")

include("utils/Integrations.jl")
include("utils/InterpolationMethods.jl")



end
