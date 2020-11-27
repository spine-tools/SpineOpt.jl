using Documenter
using SpineOpt

SpineOpt.write_system_components_file(joinpath(@__DIR__, "src", "system_components.md"))

makedocs(
    sitename="SpineOpt.jl",
    format=Documenter.HTML(prettyurls=get(ENV, "CI", nothing) == "true"),
    pages=[
        "Introduction" => "index.md",
        "Getting Started" => "getting_started.md",
        "System Components" => "system_components.md",
        "Advanced Usage" => "advanced_usage.md",
        "Mathematical formulation" => Any[
            "Objective"=>joinpath("mathematical_formulation", "objective_function.md"),
            "Constraints"=>joinpath("mathematical_formulation", "constraints.md"),
        ],
        "Library" => "library.md"
    ],
)

deploydocs(repo="github.com/Spine-project/SpineOpt.jl.git", versions=["stable" => "v^", "v#.#"])
