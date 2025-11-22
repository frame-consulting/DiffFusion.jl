module DiffFusion

using ChainRulesCore
using DelimitedFiles
using Distributed
using Distributions
using FiniteDifferences
using ForwardDiff
using Interpolations
using LinearAlgebra
using LsqFit
using OrderedCollections
using Printf
using ProgressBars
using QuadGK
using Random
using Roots
using SharedArrays
using Sobol
using SparseArrays
using StatsBase
using Zygote

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
include("termstructures/credit/CreditDefaultTermstructures.jl")
include("termstructures/parameter/ParameterTermstructures.jl")
include("termstructures/rates/YieldTermstructures.jl")
include("termstructures/volatility/VolatilityTermstructures.jl")

include("models/Model.jl")
include("models/asset/AssetModel.jl")
include("models/asset/CevAssetModel.jl")
include("models/asset/LognormalAssetModel.jl")
include("models/credit/CoxIngersollRossModel.jl")
include("models/hybrid/CompositeModel.jl")
include("models/hybrid/SimpleModel.jl")
include("models/hybrid/DiagonalModel.jl")
include("models/rates/SeparableHjmModel.jl")
include("models/rates/GaussianHjmModel.jl")
include("models/rates/ForwardRateVolatility.jl")
include("models/rates/SwapRateVolatility.jl")
include("models/rates/SwapRateCalibration.jl")
include("models/futures/MarkovFutureModels.jl")

include("models/asset/AssetVolatility.jl")
include("models/asset/AssetCalibration.jl")
include("models/inflation/ConvexityAdjustment.jl")

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
include("payoffs/RatesOptions.jl")
include("payoffs/AmcPayoffs.jl")
include("payoffs/AssetOptions.jl")
include("payoffs/BarrierOptions.jl")

include("products/Cashflows.jl")
include("products/AssetOptionFlows.jl")
include("products/RatesCoupons.jl")
include("products/RelativeReturnCoupon.jl")
include("products/RelativeReturnIndexCoupon.jl")

include("products/CashFlowLeg.jl")
include("products/SwaptionLeg.jl")
include("products/MtMCashFlowLeg.jl")
include("products/CashAndAssetLegs.jl")
include("products/BermudanSwaptionLeg.jl")

include("utils/Bachelier.jl")
include("utils/Barriers.jl")
include("utils/Black.jl")
include("utils/BrownianBridge.jl")
include("utils/Gradients.jl")
include("utils/Integrations.jl")
include("utils/InterpolationMethods.jl")
include("utils/PolynomialRegression.jl")
include("utils/PiecewiseRegression.jl")

include("analytics/Scenarios.jl")
include("analytics/ScenariosParallel.jl")
include("analytics/Analytics.jl")
include("analytics/Collateral.jl")
include("analytics/Valuations.jl")
include("analytics/Covariances.jl")

include("serialisation/Serialisations.jl")
include("serialisation/Array.jl")
include("serialisation/Termstructures.jl")
include("serialisation/Models.jl")
include("serialisation/RebuildModels.jl")
include("serialisation/RebuildTermstructures.jl")
include("serialisation/ReadTermstructures.jl")

module Examples
    using DiffFusion
    using DiffFusion:ModelTime
    using DiffFusion:ModelValue
    using OrderedCollections
    using Random
    using YAML
    #
    include("examples/csv/csv.jl")
    include("examples/yaml/yaml.jl")
    include("examples/Examples.jl")
    include("examples/Models.jl")
    include("examples/Products.jl")
end # module

# Zygote is broken with Julia 1.12; we may exclude Zygote at some point
const _use_zygote = true
if _use_zygote
    include("analytics/ValuationsViaZygote.jl")
    include("chainrules/control.jl")
    include("chainrules/models.jl")
    include("chainrules/termstructures.jl")
    include("chainrules/simulations.jl")
end

"List of function names eligible for de-serialisation."
const _eligible_func_names = [ string(n) for n in names(DiffFusion; all = true, imported = false) ]

include("precompile/precompile.jl")
end
