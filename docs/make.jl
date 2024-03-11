using Documenter
using SpineOpt

include("docs_utils.jl")

# Automatically write the `Concept Reference` files using the `spineopt_template.json` as a basis.
# Actual descriptions are fetched separately from `src/concept_reference/concepts/`
path = @__DIR__
default_translation = Dict(
    # ["tool_features"] => "Tool Features",
    ["relationship_classes"] => "Relationship Classes",
    ["parameter_value_lists"] => "Parameter Value Lists",
    # ["features"] => "Features",
    # ["tools"] => "Tools",
    ["object_parameters", "relationship_parameters"] => "Parameters",
    ["object_classes"] => "Object Classes",
)
concept_dictionary = add_cross_references!(
    initialize_concept_dictionary(SpineOpt.template(); translation = default_translation),
)
write_concept_reference_files(concept_dictionary, path)

# Automatically write the 'constraints_automatically_generated' file using the 'constraints' file
# and content from docstrings
mathpath = joinpath(path, "src", "mathematical_formulation")
docstrings = all_docstrings(SpineOpt)
constraints_lines = readlines(joinpath(mathpath, "constraints.md"))
expand_tags!(constraints_lines, docstrings)
open(joinpath(mathpath, "constraints_automatically_generated.md"), "w") do file
    write(file, join(constraints_lines, "\n"))
end

write_sets_and_variables(mathpath)

# Generate the documentation pages
# Replace the Any[...] with just Any[] if you want to collect content automatically via `expand_empty_chapters!`
pages = [
    "Introduction" => "index.md",
    "Getting Started" => Any[
        "Installation" => joinpath("getting_started", "installation.md"),
        "Setting up a workflow" => joinpath("getting_started", "setup_workflow.md"),
        "Creating Your Own Model" => joinpath("getting_started", "creating_your_own_model.md"),
        "Archetypes" => joinpath("getting_started", "archetypes.md"),
        "Managing Outputs" => joinpath("getting_started", "output_data.md"),
    ],
    "Tutorials" => Any[
        "Webinars" => joinpath("tutorial", "webinars.md"),
        "Simple system" => joinpath("tutorial", "simple_system.md"),
        "Stochastic system" => joinpath("tutorial", "stochastic_system.md"),
        "Reserve requirements" => joinpath("tutorial", "reserves.md"),
        "Ramping constraints" => joinpath("tutorial", "ramping.md"),
        "Unit Commitment" => joinpath("tutorial", "unit_commitment.md"),
        "Two hydro plants" => joinpath("tutorial", "tutorialTwoHydro.md"),
        "Case Study A5" => joinpath("tutorial", "case_study_a5.md"),
    ],
    "How to" => [],
    "Concept Reference" => Any[
        "Basics of the model structure" => joinpath("concept_reference", "the_basics.md"),
        "Object Classes" => joinpath("concept_reference", "Object Classes.md"),
        "Relationship Classes" => joinpath("concept_reference", "Relationship Classes.md"),
        "Parameters" => joinpath("concept_reference", "Parameters.md"),
        "Parameter Value Lists" => joinpath("concept_reference", "Parameter Value Lists.md"),
    ],
    "Mathematical Formulation" => Any[
        "Variables" => joinpath("mathematical_formulation", "variables.md"),
        "Constraints" => joinpath("mathematical_formulation", "constraints_automatically_generated.md"),
        "Objective" => joinpath("mathematical_formulation", "objective_function.md"),
    ],
    "Advanced Concepts" => Any[
        "Temporal Framework" => joinpath("advanced_concepts", "temporal_framework.md"),
        "Stochastic Framework" => joinpath("advanced_concepts", "stochastic_framework.md"),
        "Unit Commitment" => joinpath("advanced_concepts", "unit_commitment.md"),
        "Ramping" => joinpath("advanced_concepts", "ramping.md"),
        "Reserves" => joinpath("advanced_concepts", "reserves.md"),
        "Investment Optimization" => joinpath("advanced_concepts", "investment_optimization.md"),
        "User Constraints" => joinpath("advanced_concepts", "user_constraints.md"),
        "Decomposition" => joinpath("advanced_concepts", "decomposition.md"),
        "PTDF-Based Powerflow" => joinpath("advanced_concepts", "powerflow.md"),
        "Pressure driven gas transfer" => joinpath("advanced_concepts", "pressure_driven_gas_transfer.md"),
        "Lossless nodal DC power flows" => joinpath("advanced_concepts", "Lossless_DC_power_flow.md"),
        "Representative days with seasonal storages" => joinpath(
            "advanced_concepts", "representative_days_w_seasonal_storage.md",
        ),
        "Imposing renewable energy targets" => joinpath("advanced_concepts", "cumulated_flow_restrictions.md"),
        "Modelling to generate alternatives" => joinpath("advanced_concepts", "mga.md"),
    ],
    "Implementation details" => [],
    "Library" => "library.md",
]
populate_empty_chapters!(pages, joinpath(path, "src"))

# Create and deploy the documentation
makedocs(
    sitename = "SpineOpt.jl",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true", size_threshold = 409600, assets = ["assets/style.css"]),  # uncomment to deploy locally
    pages = pages,
    warnonly = true,
)
deploydocs(repo = "github.com/spine-tools/SpineOpt.jl.git", versions = ["stable" => "v^", "v#.#"])
