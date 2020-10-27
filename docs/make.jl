using Documenter, SpineOpt
include("$(@__DIR__)\\src\\write_systemcomponents.jl")
makedocs(
    sitename = "SpineOpt.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    pages = [
        "Getting Started" => "gettingstarted.md",
        "System Components" => "systemcomponents.md",
        "Advanced Usage" => "advancedusage.md",
        "Mathematical formulation" => Any[
        "Objective" => "Mathematicalformulation\\objectivefunction.md",
        "Constraints" => "Mathematicalformulation\\constraints.md"
        ]
    ]
)

deploydocs(
    repo  = "github.com/Spine-project/SpineOpt.jl.git",
    versions = ["stable" => "v^", "v#.#"],
)
