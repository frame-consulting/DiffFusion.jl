push!(LOAD_PATH,"src/")
push!(LOAD_PATH,"../src/")

using Documenter
using DiffFusion

"""
A type alias for variables representing time.
"""
ModelTime = Float64

"""
A type alias for variables representing modelled quantities.
"""
ModelValue = Number


makedocs(
    sitename = "[∂F]",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [DiffFusion],
    pages = [
        "Home" => "index.md",
        "Introduction" => Any[
            "introduction/overview.md",
            "introduction/simulation_framework.md",
        ],
        "Term Structures" => Any[
            "termstructures/termstructures.md",
            "termstructures/yield_curves.md",
            "termstructures/volatilities.md",
            "termstructures/parameters.md",
            "termstructures/correlations.md",
            "Others" => "termstructures/others.md",
        ],
        "Models" => Any[
            "models/rates_models.md",
            "models/asset_models.md",
            "models/futures_models.md",
            "models/credit_models.md",
            "models/cross_asset_models.md",
            "models/models.md",
        ],
        #
        "simulations/simulations.md",
        "Pricing Configuration" => Any[
            "pricing_configuration/context.md",
            "pricing_configuration/paths.md",
        ],
        "Products" => Any[
            "products/cash_flows.md",
            "products/products.md",
            "products/swaptions.md",
        ],
        "Scenarios" => Any[
            "scenarios/scenario_generation.md",
            "scenarios/exposure_calculation.md",
            "scenarios/collateral_simulation.md",
        ],
        "Payoffs" => Any[
            "payoffs/payoffs.md",
            "payoffs/rates_payoffs.md",
            "payoffs/asset_payoffs.md",
            "payoffs/amc_payoffs.md",
        ],
        "sensitivities/sensitivities.md",
        "analytics/analytics.md",
        "examples/examples.md",
        "serialisation/serialisation.md",
        "utils/utils.md",
        "additional_functions/additional_functions.md",
        "function_index/function_index.md",
    ],
    warnonly = [:missing_docs, ],
)

deploydocs(
    repo = "https://github.com/frame-consulting/DiffFusion.jl",
    push_preview = true,
)
