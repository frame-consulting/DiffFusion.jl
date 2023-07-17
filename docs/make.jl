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
        "pages/function_index.md",
    ],
)

deploydocs(
    repo = "https://github.com/frame-consulting/DiffFusion.jl",
)
