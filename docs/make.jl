using Documenter
using SpineOpt

#the function below needs to be moved to src/util/docs_utils but src/util is currently in development in another branch
"""
    drag_and_drop(pages, path)

Reads the folder and file structure to automatically create the documentation, effectively creating a drag and drop feature for select chapters. The functionality is activated for empty chapters ("chapter name" => nothing).

The code assumes a specific structure.
+ All chapters and corresponding markdownfiles are in the "docs/src folder".
+ folder names need to be lowercase with underscores because folder names are derived from the page names
+ markdown file names can have uppercases and can have underscores but don't need to because the page names are derived from file names

An alternative approach for this code could be to automatically go over all folders and files (removing the need for a specific structure) and instead use a list "exclude" which indicates which folders and files should be skipped. To deal with folders in folders we could use walkdir() instead of readdir()
"""
function drag_and_drop(pages,path)
    # collect folders as chapters and markdownfiles as pages
    chaptex=Dict()
    for dir in readdir(path*"/src")
        if isdir(path*"/src/"*dir)
            chaptex[dir]=[rd for rd in readdir(path*"/src/"*dir) if !isdir(path*"/src/"*dir*"/"*rd) && (rd[end-1:end]=="md" || rd[end-1:end]=="MD")]
        end
    end

    # replace all empty chapters with the 'drag and drop' files
    newpages=[]
    for page in pages
        chapname=page.first
        chapfile=lowercase(replace(chapname," "=>"_"))
        if chapfile in keys(chaptex) && page.second==nothing
            texlist=Any[]
            for texfile in chaptex[chapfile]
                texname=split(texfile,".")[1]
                texname=uppercasefirst(replace(texname,"_"=>" "))
                push!(texlist,texname => joinpath(chapfile,texfile))
            end
            push!(newpages,chapname => texlist)
        else
            push!(newpages,page)
        end
    end
    return newpages
end

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

## Generate the documentation pages
pages=[
    "Introduction" => "index.md",
    "Getting Started" => Any[
        "Installation" => joinpath("getting_started", "installation.md"),
        "Setting up a workflow" => joinpath("getting_started", "setup_workflow.md"),
        "Creating Your Own Model" => joinpath("getting_started", "creating_your_own_model.md"),
        "Archetypes" => joinpath("getting_started", "archetypes.md"),
        "Managing Outputs" => joinpath("getting_started", "output_data.md")
    ],
    "Tutorials" => Any[
        "Webinars" => joinpath("tutorial", "webinars.md"),
        "Simple system" => joinpath("tutorial", "simple_system.md"),
        "Two hydro plants" => joinpath("tutorial", "tutorialTwoHydro.md"),
        "Case Study A5" => joinpath("tutorial", "case_study_a5.md")
    ],
    "How to" => nothing #=Any[
        "change the solver" => joinpath("how_to", "change_the_solver.md"),
        "define an efficiency" => joinpath("how_to", "define_an_efficiency.md"),
        "print the model" => joinpath("how_to", "print_the_model.md")
    ]=#,
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
    "Implementation details" => nothing #=Any[
        "Documentation" => joinpath("implementation_details", "documentation.md"),
        "Parameter type" => joinpath("implementation_details", "parameter_type.md")
    ]=#,
    "Library" => "library.md",
]
newpages=drag_and_drop(pages,path)

## Create and deploy the documentation
makedocs(
    sitename="SpineOpt.jl",
    #format=Documenter.HTML(prettyurls=get(ENV, "CI", nothing) == "true"),
    pages=newpages,
)
deploydocs(repo="github.com/spine-tools/SpineOpt.jl.git", versions=["stable" => "v^", "v#.#"])