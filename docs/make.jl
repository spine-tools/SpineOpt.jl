using Documenter
using SpineOpt

include("docs_utils.jl")

# Automatically write the `Concept Reference` files using the `spineopt_template.json` as a basis.
# Actual descriptions are fetched separately from `src/concept_reference/concepts/`
path = @__DIR__
default_translation = Dict(
    "relationship_classes" => "Relationship Classes",
    "parameter_value_lists" => "Parameter Value Lists",
    "object_parameters" => "Parameters",
    "relationship_parameters" => "Parameters",
    "object_classes" => "Object Classes",
)
concept_dict = concept_dictionary(SpineOpt.template(); translation = default_translation)
write_concept_reference_files(concept_dict, path)

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
        "Verify installation" => joinpath("getting_started", "recommended_workflow.md"),
        "Troubleshooting" => joinpath("getting_started", "troubleshooting.md"),
        "Performace tips" => joinpath("getting_started", "performance_tips.md"),
        "Known issues" => joinpath("getting_started", "known_issues.md"),
    ],
    "Tutorials" => Any[
        "Webinars" => joinpath("tutorial", "webinars.md"),
        "Simple system" => joinpath("tutorial", "simple_system.md"),
        "Temporal resolution" => joinpath("tutorial", "temporal_resolution.md"),
        "Stochastic structure" => joinpath("tutorial", "stochastic_system.md"),
        "Capacity planning" => joinpath("tutorial", "capacity_planning.md"),
        "Multi-year investments using economic parameters" => joinpath("tutorial", "multi-year_investment.md"),
        "Reserve requirements" => joinpath("tutorial", "reserves.md"),
        "Ramping constraints" => joinpath("tutorial", "ramping.md"),
        "Unit Commitment" => joinpath("tutorial", "unit_commitment.md"),
    ],
    "How to" => [],
    "Example gallery" => joinpath("gallery", "gallery.md"),    
    "Database structure" => Any[
        "Basics of the data structure" => joinpath("concept_reference", "the_basics.md"),
        "Archetypes" => joinpath("concept_reference", "archetypes.md"),
    ],
    "Standard model framework" => Any[
        "Temporal Framework" => joinpath("advanced_concepts", "temporal_framework.md"),
        "Stochastic Framework" => joinpath("advanced_concepts", "stochastic_framework.md"),
    ],
    "Standard model features" => Any[
        "Unit Commitment" => joinpath("advanced_concepts", "unit_commitment.md"),
        "Investment Optimization" => joinpath("advanced_concepts", "investment_optimization.md"),
        "Multi-year Investments" => joinpath("advanced_concepts", "multi-year.md"),
        "Reserves" => joinpath("advanced_concepts", "reserves.md"),
        "Ramping" => joinpath("advanced_concepts", "ramping.md"),
        "Lossless nodal DC power flows" => joinpath("advanced_concepts", "Lossless_DC_power_flow.md"),
        "PTDF-Based Powerflow" => joinpath("advanced_concepts", "powerflow.md"),
        "Pressure driven gas transfer" => joinpath("advanced_concepts", "pressure_driven_gas_transfer.md"),
        "User Constraints" => joinpath("advanced_concepts", "user_constraints.md"),
    ],
    "Algorithms" => Any[
        "Decomposition" => joinpath("advanced_concepts", "decomposition.md"),
        "Modelling to generate alternatives" => joinpath("advanced_concepts", "mga.md"),
        "Multi-stage optimisation" => joinpath("advanced_concepts", "multi_stage.md"),
    ],
    "SpineOpt Template" => Any[
        "Object Classes" => joinpath("concept_reference", "Object Classes.md"),
        "Relationship Classes" => joinpath("concept_reference", "Relationship Classes.md"),
        "Parameters" => joinpath("concept_reference", "Parameters.md"),
        "Parameter Value Lists" => joinpath("concept_reference", "Parameter Value Lists.md"),
    ],
    "Mathematical Formulation" => Any[
        "Variables" => joinpath("mathematical_formulation", "variables.md"),
        "Objective" => joinpath("mathematical_formulation", "objective_function.md"),
        "Constraints" => joinpath("mathematical_formulation", "constraints_automatically_generated.md"),
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
