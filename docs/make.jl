using Documenter
using SpineOpt


# Automatically write the `Concept Reference` files using the `spineopt_template.json` as a basis.
# Actual descriptions are fetched separately from `src/concept_reference/concepts/`
SpineOpt.write_concept_reference_file(
    @__DIR__,
    "object_classes.md",
    ["object_classes"],
    "Object Classes";
    template_description_index=2
)
SpineOpt.write_concept_reference_file(
    @__DIR__,
    "relationship_classes.md",
    ["relationship_classes"],
    "Relationship Classes";
    template_related_concept_index=2,
    template_related_concept_names=["Object Classes"],
    template_description_index=3
)
SpineOpt.write_concept_reference_file(
    @__DIR__,
    "parameters.md",
    ["object_parameters", "relationship_parameters"],
    "Parameters";
    template_name_index=2,
    template_related_concept_index=1,
    template_related_concept_names=["Object Classes", "Relationship Classes"],
    template_default_value_index=3,
    template_parameter_value_list_index=4,
    template_description_index=5
)
SpineOpt.write_concept_reference_file(
    @__DIR__, "parameter_value_lists.md", ["parameter_value_lists"], "Parameter Value Lists"
)

# Create and deploy the documentation
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
            "Basics of the model structure"=>joinpath("concept_reference", "the_basics.md"),
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
            "Temporal Framework"=>joinpath("advanced_concepts", "temporal_framework.md"),
            "Stochastic Framework"=>joinpath("advanced_concepts", "stochastic_framework.md"),
            "Investment Optimization"=>joinpath("advanced_concepts", "investment_optimization.md")
        ],
        "Library" => "library.md"
    ],
)

deploydocs(repo="github.com/Spine-project/SpineOpt.jl.git", versions=["stable" => "v^", "v#.#"])
