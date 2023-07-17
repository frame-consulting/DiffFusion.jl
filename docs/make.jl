push!(LOAD_PATH,"src/")
push!(LOAD_PATH,"../src/")

using Documenter
using DiffFusion


makedocs(
    sitename = "[∂F]",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [DiffFusion],
    pages = [
        "index.md",
        "pages/overview.md",
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
)

deploydocs(
    repo = "https://github.com/frame-consulting/DiffFusion.jl",
)
