# Archetypes

Archetypes are essentially ready-made templates for different aspects of *SpineOpt.jl*.
They are intended to serve both as examples for *how* the data structure in *SpineOpt.jl* works,
as well as pre-made modular parts that can be imported on top of existing model input data.

The `templates/models/basic_model_template.json` contains a ready-made template for simple energy system models,
with uniform time resolution and deterministic stochastic structure.
Essentially, it serves as a basis for testing how the modelled system is set up,
without having to worry about setting up the temporal and stochastic structures.

The rest of the different archetypes are included under `templates/archetypes` in the *SpineOpt.jl* repository.
Each archetype is stored as a `.json` file containing the necessary [objects](@ref introduction-to-object-classes),
[relationships](@ref introduction-to-relationship-classes), and [parameters](@ref introduction-to-parameters)
to form a functioning pre-made part for a *SpineOpt.jl* model.
The archetypes aren't completely plug-and-play, as there are always some [relationships](@ref introduction-to-relationship-classes)
required to connect the archetype to the other input data correctly.
Regardless, the following sections explain the different archetypes included in the *SpineOpt.jl* repository,
as well as what steps the user needs to take to connect said archetype to their input data correctly.

## Loading the SpineOpt Template and Archetypes into Your Model
To load the latest version of the SpineOpt template, in the Spine DB Editor, from the menu (three horizontal bars in the top right), click on import as follows:

![importing the SpineOpt Template](https://user-images.githubusercontent.com/7080191/156589727-baa578b6-41f2-4de8-beb1-27ec4bddb5d6.png)

Change the file type to JSON and click on spineopt_template.json as follows:

![importing the SpineOpt Template](https://user-images.githubusercontent.com/7080191/156590071-d26125ec-8b76-4853-9a31-1df5508fa793.png)


Click on spineopt_template.json and press Open. If you don't see spineopt_template.json make sure you have navigated to `Spine\SpineOpt.jl\templates`.

Loading the latest version of the SpineOpt template in this way will update your datastore with the latest version of the data structure.

## Branching Stochastic Tree

>`templates/archetypes/branching_stochastic_tree.json`

This archetype contains the definitions required for an example [stochastic\_structure](@ref) called `branching`, representing a
branching scenario tree.
The [stochastic\_structure](@ref) starts out as a single [stochastic\_scenario](@ref) called `realistic`,
which then branches out into three roughly equiprobable [stochastic\_scenario](@ref)s called `forecast1`, `forecast2`, and `forecast3` after 6 hours.
This archetype is the final product of following the steps in the [Example of branching stochastics](@ref) part
of the [Stochastic Framework](@ref) section.

Importing this archetype into an input datastore only creates the [stochastic\_structure](@ref),
which needs to be connected to the rest of your model using either the [model\_\_default\_stochastic\_structure](@ref) relationship
for a model-wide default, or the other relevant [Structural relationship classes](@ref).
Note that the model-wide default gets superceded by any conflicting definitions via e.g. the [node\_\_stochastic\_structure](@ref).

## Converging Stochastic Tree

>`templates/archetypes/converging_stochastic_tree.json`

This archetype contains the definitions required for an example [stochastic\_structure](@ref) called `converging`, representing a
converging scenario tree *(technically a directed acyclic graph DAG)*.
The [stochastic\_structure](@ref) starts out as a single [stochastic\_scenario](@ref) called `realization`,
which then branches out into three roughly equiprobable [stochastic\_scenario](@ref)s called `forecast1`, `forecast2`, and `forecast3` after 6 hours.
Then, after 24 hours *(1 day)*, these three forecasts converge into a single [stochastic\_scenario](@ref) called `converged_forecast`.
This archetype is the final product of following the steps in the [Example of converging stochastics](@ref) part
of the [Stochastic Framework](@ref) section.

Importing this archetype into an input datastore only creates the [stochastic\_structure](@ref),
which needs to be connected to the rest of your model using either the [model\_\_default\_stochastic\_structure](@ref) relationship
for a model-wide default, or the other relevant [Structural relationship classes](@ref).
Note that the model-wide default gets superceded by any conflicting definitions via e.g. the [node\_\_stochastic\_structure](@ref).

## Deterministic Stochastic Structure

>`templates/archetypes/deterministic_stochastic_structure.json`

This archetype contains the definitions required for an example [stochastic\_structure](@ref) called `deterministic`, representing a simple deterministic modelling case.
The [stochastic\_structure](@ref) contains only a single [stochastic\_scenario](@ref) called `realization`, which continues indefinitely.
This archetype is the final product of following the steps in the [Example of deterministic stochastics](@ref) part
of the [Stochastic Framework](@ref) section.

Importing this archetype into an input datastore only creates the [stochastic\_structure](@ref),
which needs to be connected to the rest of your model using either the [model\_\_default\_stochastic\_structure](@ref) relationship
for a model-wide default, or the other relevant [Structural relationship classes](@ref).
Note that the model-wide default gets superceded by any conflicting definitions via e.g. the [node\_\_stochastic\_structure](@ref).