push!(LOAD_PATH,"src/")
push!(LOAD_PATH,"../src/")

using Documenter
using DiffFusion

"""
A type alias for variables representing time.
"""
ModelTime = Number

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
        "index.md",
        "pages/overview.md",
        "pages/simulation_framework.md",
        #
        "termstructures/termstructures.md",
        "models/models.md",
        "models/rates_models.md",
        "simulations/simulations.md",
        "paths/paths.md",
        "payoffs/payoffs.md",
        "products/products.md",
        "analytics/analytics.md",
        #
        "examples/examples.md",
        "serialisation/serialisation.md",
        "utils/utils.md",
        "pages/additional_functions.md",
        "pages/function_index.md",
    ],
    warnonly = [:missing_docs, ],
)

deploydocs(
    repo = "https://github.com/frame-consulting/DiffFusion.jl",
    push_preview = true,
)
