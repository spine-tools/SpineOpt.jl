using Documenter, SpineOpt
include("$(@__DIR__)\\src\\write_systemcomponents.jl")
makedocs(
    sitename = "SpineOpt.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    pages = [
        "Getting Started" => "getting_started.md",
        "System Components" => "system_components.md",
        "Advanced Usage" => "advanced_usage.md",
        "Mathematical formulation" => Any[
        "Objective" => "mathematical_formulation\\objective_function.md",
        "Constraints" => "mathematical_formulation\\constraints.md"
        ]
    ]
)

deploydocs(
    repo  = "github.com/Spine-project/SpineOpt.jl.git",
    versions = ["stable" => "v^", "v#.#"],
)
