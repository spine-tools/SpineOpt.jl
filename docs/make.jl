using Documenter, SpineOpt

makedocs(
    sitename = "SpineOpt.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    pages = [
        "Getting Started" => "gettingstarted.md",
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
