# Introduction

*SpineOpt.jl* is an integrated energy systems optimization model, striving towards adaptability for a multitude of modelling purposes.
The data-driven model structure allows for highly customizable energy system descriptions, as well as flexible
temporal and stochastic structures, without the need to alter the model source code directly.
The methodology is based on mixed-integer linear programming (MILP), and *SpineOpt* relies on
[*JuMP.jl*](https://github.com/JuliaOpt/JuMP.jl) for interfacing with the different solvers.

While, in principle, it is possible to run *SpineOpt* by itself, it has been designed to be used through the
[Spine toolbox](https://github.com/spine-tools/Spine-Toolbox), and take maximum advantage of the data and modelling
workflow management tools therein.
Thus, we highly recommend installing *Spine Toolbox* as well, as outlined in the [Installation](@ref) guide.

## Important remark on spine entities

The documentation often refers to objects and relationships. These are actually both entities in a spine database (technically they are entities with one dimension and multiple dimensions respectively). The distinction here is to make a more clear distinction between the physical unit/node (entity with one dimension or object) and the flows between units and/or nodes (entities with multiple dimensions or relationships).

In this documentation the two naming structures (object/relationships or entities) will be used interchangeably. Though, in upcoming versions of the documentation, the naming structure will gravitate more towards entities.

## How the documentation is structured

Having a high-level overview of how this documentation is structured will help you know where to look for certain things.

The documentation is implicitly structured in 3 parts (documenter.jl does not explicitly support parts).

Part 1 aims to get new users started as quick as possible. It contains installation instructions (including trouble shooting), tutorials for basic usage and explains how to do some high-level things (e.g define an efficiency).

- **Getting Started**
  contains guides for starting to use *SpineOpt.jl*.
  The [Installation](@ref installation) section explains different ways to install *SpineOpt.jl* on your computer. To ensure that the installation has been done correctly, the [Recommended workflow](@ref recommended_workflow)
  section provides a guide to set up a minimal working example of *SpineOpt.jl* in *Spine Toolbox*. Some SpineOpt concepts will already be explained in this example but more information is provided in the **Concept Reference** chapter. Regardless, any issues during this example will most likely be due to the installation. If any problems are encountered, you can start with the [Trouble shooting](@ref troubleshooting) section.

- **Tutorials**
  provides guided examples for a set of basic use-cases, either as videos, written text and/or example files.
  The *SpineOpt.jl* repository includes a folder `examples` for ready-made example models.
  Each example is its own sub-folder, where the input data is provided as `.json` or `.sqlite` files.
  This way, you can easily get a feel for how SpineOpt works with pre-made datasets,
  either through [Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox), or directly from the Julia REPL.

!!! warning
  Although these examples are part of the unit tests (and should therefore be up to date), they do rely on migration scripts for their updates. That does mean that there is the possibility that there is a missing parameter that is not used by the example and as such does not trigger an error. Therefore it is not recommended to rely on these example files for building your own models.

- **How to**
  provides explanations on how to do specific high-level things that might involve multiple elements
  (e.g. how to print the model).

Part 2 explains the core principles, features and design decisions of SpineOpt without getting lost in the details.

- **Database structure**
  lists and explains all the important data and model structure related concepts to understand in *SpineOpt.jl*.
  For a mathematical modelling point of view, see the **Mathematical Formulation**
  chapter instead. The [Basics of the model structure](@ref) section briefly explains the general purpose of the most
  important concepts, like [Object Classes](@ref) and [Relationship Classes](@ref).

- **Standard model framework**
  covers the temporal and stochastic framework present in very SpineOpt model.
  The [Temporal Framework](@ref) section explains how defining *time* works in *SpineOpt.jl*, and how it can be used
  for different purposes. The [Stochastic Framework](@ref) section details how different stochastic structures can be
  defined, how they interact with each other, and how this impacts writing [Constraints](@ref) in *SpineOpt.jl*.

- **Standard model features**
  covers the features of the SpineOpt model.
  The [Investment Optimization](@ref) section explains how to include investment variables in your models.
  The [Unit commitment](@ref) section explains how clustered unit-commitment is defined,
  while the [Ramping](@ref) and [Reserves](@ref) sections explain how to enable these operational details in your model.
  The [User Constraints](@ref) section details how to include generic data-driven custom constraints.
  The remaining sections, namely [PTDF-Based Powerflow](@ref ptdf-based-powerflow),
  [Pressure driven gas transfer](@ref pressure-driven-gas-transfer), [Lossless nodal DC power flows](@ref),
  explain various use-case specific modelling approaches supported by *SpineOpt.jl*.

- **Algorithms**
  are alternative options to the standard model.
  The [Decomposition](@ref) section explains the Benders decomposition implementation included in *SpineOpt.jl*,
  as well as how to use it.
  There is also Modelling to generate alternatives and multi stage optimisation.

Part 3 contains all the detailed information you need when you are looking for something specific (e.g. a parameter name or the formulation of a constraint).

- **SpineOpt Template**
  contains a list of all the entities and parameters as you see them in the Spine Toolbox db editor.
  The [Object Classes](@ref), [Relationship Classes](@ref), [Parameters](@ref),
  and [Parameter Value Lists](@ref) sections contain detailed explanations of each and every aspect of *SpineOpt.jl*, organized into the respective sections for clarity.

- **Mathematical Formulation**
  provides the mathematical view of *SpineOpt.jl*, as some of the
  methodology-related aspects of the model are more easily understood as math than Julia code. The [Variables](@ref)
  section explains the purpose of each variable in the model, as well as how the variables are related to the different
  [Object Classes](@ref) and [Relationship Classes](@ref).
  the [Objective](@ref) section explains the default objective function used in *SpineOpt.jl*.
  The [Constraints](@ref) section contains the mathematical
  formulation of each constraint, as well as explanations to their purpose and how they are controlled via different [Parameters](@ref).

- **Implementation details**
  explains some parts of the code (for those who are interested in how things work under the hood).
  Note that this chapter is particularly sensitive to changes in the code and as such might get out of sync.
  If you do notice a discrepancy, please create an [issue in github](https://github.com/spine-tools/SpineOpt.jl/issues).
  That is also the place to be if you don't find what you are looking for in this documentation.