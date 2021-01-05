using Documenter
using SpineOpt

#=  No longer automatically write the "system_components.md" based on the "spineop_template.json"
    This functionality can be restored later if need be, but it might be possible to automate
    some of the writing, hopefully?
#SpineOpt.write_system_components_file(joinpath(@__DIR__, "src", "system_components.md"))
=#

makedocs(
    sitename="SpineOpt.jl",
    format=Documenter.HTML(prettyurls=get(ENV, "CI", nothing) == "true"),
    pages=[
        "Introduction" => "index.md",
        "Getting Started" => Any[
            "Installation"=>joinpath("getting_started", "installation.md"),
            "Running an Optimization"=>joinpath("getting_started", "running_an_optimization.md"),
            "Creating Your Own Model"=>joinpath("getting_started", "creating_your_own_model.md"),
        ],
        "Concept Reference" => Any[
            "The Basics"=>joinpath("concept_reference", "the_basics.md"),
            "Object Classes"=>joinpath("concept_reference", "object_classes.md"),
            "Relationship Classes"=>joinpath("concept_reference", "relationship_classes.md"),
            "Parameters"=>joinpath("concept_reference", "parameters.md"),
            "Parameter Value Lists"=>joinpath("concept_reference", "parameter_value_lists.md"),
        ],
        "Mathematical Formulation" => Any[
            "Variables"=>joinpath("mathematical_formulation", "variables.md"),
            "Constraints"=>joinpath("mathematical_formulation", "constraints.md"),
            "Objective"=>joinpath("mathematical_formulation", "objective_function.md"),
        ],
        "Advanced Concepts" => Any[
            "Temporal Structure"=>joinpath("advanced_concepts", "temporal_structure.md"),
            "Stochastic Structure"=>joinpath("advanced_concepts", "stochastic_structure.md"),
            "Investment Optimization"=>joinpath("advanced_concepts", "investment_optimization.md")
        ],
        "Library" => "library.md"
    ],
)

deploydocs(repo="github.com/Spine-project/SpineOpt.jl.git", versions=["stable" => "v^", "v#.#"])
