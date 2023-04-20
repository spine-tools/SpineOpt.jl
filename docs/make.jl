using Documenter
using SpineOpt

## Automatically write the `Concept Reference` files using the `spineopt_template.json` as a basis.
# Actual descriptions are fetched separately from `src/concept_reference/concepts/`
path = @__DIR__
default_translation = Dict(
    #["tool_features"] => "Tool Features",
    ["relationship_classes"] => "Relationship Classes",
    ["parameter_value_lists"] => "Parameter Value Lists",
    #["features"] => "Features",
    #["tools"] => "Tools",
    ["object_parameters", "relationship_parameters"] => "Parameters",
    ["object_classes"] => "Object Classes",
)
concept_dictionary = SpineOpt.add_cross_references!(
    SpineOpt.initialize_concept_dictionary(SpineOpt.template(); translation=default_translation),
)
SpineOpt.write_concept_reference_files(concept_dictionary, path)

## Create and deploy the documentation
makedocs(
    sitename="SpineOpt.jl",
    #format=Documenter.HTML(prettyurls=get(ENV, "CI", nothing) == "true"),
    pages=[
        "Introduction" => "index.md",
        "Getting Started" => Any[
            "Installation" => joinpath("getting_started", "installation.md"),
            "Setting up a workflow" => joinpath("getting_started", "setup_workflow.md"),
            "Creating Your Own Model" => joinpath("getting_started", "creating_your_own_model.md"),
            "Example Models" => joinpath("getting_started", "example_models.md"),
            "Archetypes" => joinpath("getting_started", "archetypes.md"),
            "Managing Outputs" => joinpath("getting_started", "output_data.md")
        ],
		"Tutorials" => Any[
		    "Simple system" => joinpath("tutorial", "simple_system.md"),
		    "Two hydro plants" => joinpath("tutorial", "tutorialTwoHydro.md"),
		    "Case Study A5" => joinpath("tutorial", "case_study_a5.md")
		],
        "Concept Reference" => Any[
            "Basics of the model structure" => joinpath("concept_reference", "the_basics.md"),
            "Object Classes" => joinpath("concept_reference", "Object Classes.md"),
            "Relationship Classes" => joinpath("concept_reference", "Relationship Classes.md"),
            "Parameters" => joinpath("concept_reference", "Parameters.md"),
            "Parameter Value Lists" => joinpath("concept_reference", "Parameter Value Lists.md"),
        ],
        "Mathematical Formulation" => Any[
            # "Sets" => joinpath("mathematical_formulation", "sets.md"),
            "Variables" => joinpath("mathematical_formulation", "variables.md"),
            "Constraints" => joinpath("mathematical_formulation", "constraints.md"),
            "Objective" => joinpath("mathematical_formulation", "objective_function.md"),
        ],
        "Advanced Concepts" => Any[
            "Temporal Framework" => joinpath("advanced_concepts", "temporal_framework.md"),
            "Stochastic Framework" => joinpath("advanced_concepts", "stochastic_framework.md"),
            "Unit Commitment" => joinpath("advanced_concepts", "unit_commitment.md"),
            "Ramping and Reserves" => joinpath("advanced_concepts", "ramping_and_reserves.md"),
            "Investment Optimization" => joinpath("advanced_concepts", "investment_optimization.md"),
            "User Constraints" => joinpath("advanced_concepts", "user_constraints.md"),
            "Decomposition" => joinpath("advanced_concepts", "decomposition.md"),
            "PTDF-Based Powerflow" => joinpath("advanced_concepts", "powerflow.md"),
            "Pressure driven gas transfer" => joinpath("advanced_concepts", "pressure_driven_gas_transfer.md"),
            "Lossless nodal DC power flows" => joinpath("advanced_concepts", "Lossless_DC_power_flow.md"),
            "Representative days with seasonal storages" => joinpath("advanced_concepts", "representative_days_w_seasonal_storage.md"),
            "Imposing renewable energy targets" => joinpath("advanced_concepts", "cumulated_flow_restrictions.md"),
            "Modelling to generate alternatives" => joinpath("advanced_concepts", "mga.md"),
        ],
        "Library" => "library.md",
    ],
)
deploydocs(repo="github.com/Spine-project/SpineOpt.jl.git", versions=["stable" => "v^", "v#.#"])
