module DiffFusion

using Distributions
using Interpolations
using LinearAlgebra
using OrderedCollections
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
include("payoffs/AmcPayoffs.jl")

include("products/Cashflows.jl")
include("products/RatesCoupons.jl")
include("products/CashFlowLeg.jl")
include("products/MtMCashFlowLeg.jl")
include("products/CashAndAssetLegs.jl")

include("utils/Integrations.jl")
include("utils/InterpolationMethods.jl")
include("utils/PolynomialRegression.jl")
include("utils/PiecewiseRegression.jl")

include("analytics/Scenarios.jl")
include("analytics/Analytics.jl")

include("serialisation/Serialisations.jl")
include("serialisation/Array.jl")
include("serialisation/Termstructures.jl")
include("serialisation/Models.jl")
include("serialisation/RebuildModels.jl")
include("serialisation/RebuildTermstructures.jl")

module Examples
    using DiffFusion
    using DiffFusion:ModelTime
    using DiffFusion:ModelValue
    using OrderedCollections
    using Random
    using YAML
    #
    include("examples/Examples.jl")
    include("examples/Models.jl")
    include("examples/Products.jl")
end # module

"List of function names eligible for de-serialisation."
const _eligible_func_names = [ string(n) for n in names(DiffFusion; all = true, imported = false) ]

end
