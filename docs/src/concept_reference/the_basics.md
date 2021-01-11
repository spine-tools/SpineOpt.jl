# Basics of the model structure

In *SpineOpt.jl*, the model structure is generated based on the input data, allowing it to be used for a multitude of
different problems.
Here, we aim to provide you with a basic understanding of the *SpineOpt.jl* model and data structure, while the
[Object Classes](@ref), [Relationship Classes](@ref), [Parameters](@ref), and [Parameter Value Lists](@ref) sections
provide more in-depth explanations of each concept.

## Introduction to `object classes`

Essentially, [Object Classes](@ref) represents different types of `objects` or *entities* that make up the model.
For example, every power plant in the model is represented as an `object` of the `object class` [unit](@ref),
every power line as an `object` of the `object class` [connection](@ref), and so forth.
In order to add any new *entity* to a model, a new `object` has to be added to desired `object class` in the input data.

Each `object class` has a very specific purpose in *SpineOpt.jl*, so understanding their differences is key.
The [Object Classes](@ref) can be divided into three distinctive groups, namely [System object classes](@ref),
[Structural object classes](@ref), and [Meta object classes](@ref).

### System `object classes`

As the name implies, *system [Object Classes](@ref)* are used to describe the system to be modelled.
Essentially, they define *what* you want to model.
These include:

- [commodity](@ref) represents different goods to be generated, consumed, transported, etc.
- [connection](@ref) handles the transfer of `commodities` between `nodes`.
- [node](@ref) ensures the balance of the [commodity](@ref) flows, and can be used to store `commodities` as well.
- [unit](@ref) handles the generation and consumption of `commodities`.

### Structural `object classes` 

*Structural [Object Classes](@ref)* are used to define the temporal and stochastic structure of the modelled problem, as
well as handle other customization options.
Unlike the above *system [Object Classes](@ref)*, the *structural [Object Classes](@ref)* are more about *how* you
want to model, instead of strictly *what* you want to model.
These include:

- [stochastic_scenario](@ref) represents a different *forecast* or another type of an *alternative time period*.
- [stochastic_structure](@ref) acts as a handle for a group of `stochastic_scenarios` with set properties.
- [temporal_block](@ref) defines a period of *time* with the desired temporal [resolution](@ref).
- [unit_constraint](@ref) is an optional custom constraint generated based on the input data.

### Meta `object classes`

*Meta [Object Classes](@ref)* are used for defining things on the level of `models` or above, like [model](@ref)
[output](@ref) and even multiple `models` for problem decompositions.
These include:

- [model](@ref) represents an individual *model*, grouping together all the things relevant for itself.
- [output](@ref) defines which [Variables](@ref) are output from the [model](@ref).
- [report](@ref) groups together multiple [output](@ref) `objects`.

## Introduction to `relationship classes`

## Introduction to `parameters`