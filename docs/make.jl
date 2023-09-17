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
        "analytics/analytics.md",
        "examples/examples.md",
        "models/models.md",
        "paths/paths.md",
        "payoffs/payoffs.md",
        "products/products.md",
        "serialisation/serialisation.md",
        "simulations/simulations.md",
        "termstructures/termstructures.md",
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
