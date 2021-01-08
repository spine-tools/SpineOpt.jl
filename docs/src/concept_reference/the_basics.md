# Basics of the model structure

In *SpineOpt.jl*, the model structure is generated based on the input data, allowing it to be used for a multitude of
different problems.
Here, we aim to provide you with a basic understanding of the *SpineOpt.jl* model and data structure, while the
[Object Classes](@ref), [Relationship Classes](@ref), [Parameters](@ref), and [Parameter Value Lists](@ref) sections
provide more in-depth explanations of the different concepts.

## Introduction to `object classes`

Essentially, [Object Classes](@ref) represents different types of `objects` or *entities* that make up the model.
For example, every power plant in the model is represented as an `object` of the `object class` [unit](@ref),
every power line as an `object` of the `object class` [connection](@ref), and so forth.
In order to add any new *entity* to a model, a new `object` has to be added to desired `object class` in the input data.

Each `object class` has a very specific purpose in *SpineOpt.jl*, so understanding their differences is key.
The [Object Classes](@ref) can be divided into three distinctive groups, namely [System object classes](@ref),
[Structural object classes](@ref), and [Model object classes](@ref).

### System `object classes`

As the name implies, system [Object Classes](@ref) are used to describe the system to be modelled.
These include:

- [commodity](@ref)

### Structural `object classes` 

### Model `object classes`

## Introduction to `relationship classes`

## Introduction to `parameters`