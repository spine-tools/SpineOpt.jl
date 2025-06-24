# Basics of the model structure

In *SpineOpt.jl*, the model structure is generated based on the input data, allowing it to be used for a multitude of
different problems.
Here, we aim to provide you with a basic understanding of the *SpineOpt.jl* model and data structure, while the
[Object Classes](@ref), [Relationship Classes](@ref), [Parameters](@ref), and [Parameter Value Lists](@ref) sections
provide more in-depth explanations of each concept.


## [Introduction to `object classes`](@id introduction-to-object-classes)

Essentially, [Object Classes](@ref) represents different types of `objects` or *entities* that make up the model.
For example, every power plant in the model is represented as an `object` of the `object class` [unit](@ref),
every power line as an `object` of the `object class` [connection](@ref), and so forth.
In order to add any new *entity* to a model, a new `object` has to be added to desired `object class` in the input data.

Each `object class` has a very specific purpose in *SpineOpt.jl*, so understanding their differences is key.
The [Object Classes](@ref) can be roughly divided into three distinctive groups, namely [Systemic object classes](@ref),
[Structural object classes](@ref), and [Meta object classes](@ref).

### Systemic `object classes`

As the name implies, *system [Object Classes](@ref)* are used to describe the system to be modelled.
Essentially, they define *what* you want to model.
These include:

- [connection](@ref) handles the transfer of `commodities` between `nodes`.
- [grid](@ref) represents different networks where different commodities can be generated, consumed, transported, etc.
- [node](@ref) ensures the balance of the commodity flows, and can be used to store commodities as well.
- [unit](@ref) handles the generation and consumption of `commodities`.

### Structural `object classes`

*Structural [Object Classes](@ref)* are used to define the temporal and stochastic structure of the modelled problem, as
well as custom [User Constraints](@ref).
Unlike the above *system [Object Classes](@ref)*, the *structural [Object Classes](@ref)* are more about *how* you
want to model, instead of strictly *what* you want to model.
These include:

- [stochastic\_scenario](@ref) represents a different *forecast* or another type of an *alternative time period*.
- [stochastic\_structure](@ref) acts as a handle for a group of `stochastic_scenarios` with set properties.
- [temporal\_block](@ref) defines a period of *time* with the desired temporal [resolution](@ref).
- [user\_constraint](@ref) is an optional custom constraint generated based on the input data.

### Meta `object classes`

*Meta [Object Classes](@ref)* are used for defining things on the level of `models` or above, like [model](@ref)
[output](@ref) and even multiple `models` for problem decompositions.
These include:

- [model](@ref) represents an individual *model*, grouping together all the things relevant for itself.
- [output](@ref) defines which [Variables](@ref) are output from the [model](@ref).
- [report](@ref) groups together multiple [output](@ref) `objects`.


## [Introduction to `relationship classes`](@id introduction-to-relationship-classes)

While [Object Classes](@ref) define all the `objects` or *entities* that make up a [model](@ref),
[Relationship Classes](@ref) define how those *entities* are related to each other.
Thus, [Relationship Classes](@ref) hold no meaning on their own, and always include at least one `object class`.

Similar to [Object Classes](@ref), each `relationship class` has a very specific purpose in *SpineOpt.jl*, and
understanding the purpose of each `relationship class` is paramount.
The [Relationship Classes](@ref) can be roughly divided into [Systemic relationship classes](@ref),
[Structural relationship classes](@ref), and [Meta relationship classes](@ref), again similar to [Object Classes](@ref).

### Systemic `relationship classes`

*Systemic [Relationship Classes](@ref)* define how [Systemic object classes](@ref) are related to each other,
thus helping define the system to be modelled.
Most of these relationships deal with *which* `units` and `connections` interact with *which* `nodes`, and *how* those
interactions work.
This essentially defines the possible commodity flows to be modelled.
*Systemic [Relationship Classes](@ref)* include:

- [connection\_\_from\_node](@ref) defines which [node](@ref) the [connection](@ref) can transfer a commodity from.
- [connection\_\_to\_node](@ref) defines which [node](@ref) the [connection](@ref) can transfer a commodity to.
- [connection\_\_node\_\_node](@ref) holds [Parameters](@ref) for `connections` between two `nodes`.
- [node\_\_grid](@ref) defines which [node](@ref) is part of which [grid](@ref).
- [node\_\_node](@ref) holds parameters for direct [node](@ref)-[node](@ref) interactions, like diffusion of `commodities`.
- [node\_\_to\_unit](@ref) defines which [node](@ref) the [unit](@ref) can take an input commodity from.
- [unit\_\_to\_node](@ref) defines which [node](@ref) the [unit](@ref) can output a commodity to.
- [unit\_\_node\_\_node](@ref) holds parameters for [unit](@ref) interactions between two `nodes`.

### Structural `relationship classes`

*Structural [Relationship Classes](@ref)* primarily relate [Structural object classes](@ref) to
[Systemic object classes](@ref), defining what *structures* the individual parts of the *system* use.
These are mostly used to determine the temporal and stochastic structures to be used in different parts of the
modelled *system*, or custom [User Constraints](@ref).

*SpineOpt.jl* has a very flexible temporal and stochastic structure, explained in detail in the
[Temporal Framework](@ref) and [Stochastic Framework](@ref) sections of the documentation.
Unfortunately, this flexibility requires quite a few different *structural [Relationship Classes](@ref)*,
the most important of which are the following *basic structural [Relationship Classes](@ref)*:

- [node\_\_stochastic\_structure](@ref) defines the [stochastic\_structure](@ref) used for the [node](@ref) balance.
- [node\_\_temporal\_block](@ref) defines the `temporal blocks` used for the [node](@ref) balance.
- [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) defines the *stochastic directed acyclic graph (DAG)* of the [Stochastic Framework](@ref).
- [stochastic\_structure\_\_stochastic\_scenario](@ref) holds parameters for `stochastic scenarios` in the [stochastic\_structure](@ref).
- [units\_on\_\_stochastic\_structure](@ref) defines the [stochastic\_structure](@ref) used for the online variable of the [unit](@ref).
- [units\_on\_\_temporal\_block](@ref) defines the `temporal blocks` used for the online variable of the [unit](@ref).

Furthermore, there are also a number of *advanced structural [Relationship Classes](@ref)*, which are only necessary when
using some of the optional features of *SpineOpt.jl*.
For [Investment Optimization](@ref), the following relationships control the stochastic and temporal structures
of the investment [variables](@ref Variables):

- [connection\_\_investment\_stochastic\_structure](@ref) defines the [stochastic\_structure](@ref) used for the investment [Variables](@ref) for the [connection](@ref).
- [connection\_\_investment\_temporal\_block](@ref) defines the `temporal blocks` used for the investment [Variables](@ref) for the [connection](@ref).[user\_constraint](@ref).
- [node\_\_investment\_stochastic\_structure](@ref) defines the [stochastic\_structure](@ref) used for the investment [Variables](@ref) for the [node](@ref).
- [node\_\_investment\_temporal\_block](@ref) defines the [stochastic\_structure](@ref) used for the investment [Variables](@ref) for the [node](@ref).
- [unit\_\_investment\_stochastic\_structure](@ref) defines the [stochastic\_structure](@ref) used for the investment [Variables](@ref) for the [unit](@ref).
- [unit\_\_investment\_temporal\_block](@ref) defines the `temporal blocks` used for the investment [Variables](@ref) for the [unit](@ref).(@ref).

For [User Constraints](@ref), which are essentially generic data-driven custom constraints,
the following relationships are used to control which [variables](@ref Variables) are included and with what coefficients:  

- [connection\_\_from\_node\_\_user\_constraint](@ref) holds [Parameters](@ref) for the [connection\_flow](#Variables) variable *from* the [node](@ref) in question in the custom [user\_constraint](@ref).
- [connection\_\_to\_node\_\_user\_constraint](@ref) holds [Parameters](@ref) for the [connection\_flow](#Variables) variable *to* the [node](@ref) in question in the custom [user\_constraint](@ref).
- [node\_\_user\_constraint](@ref) holds [Parameters](@ref) for the [node\_state](#Variables) variable in the custom [user\_constraint](@ref).
- [unit\_flow\_\_user\_constraint](@ref) holds [Parameters](@ref) for the [unit\_flow](#Variables) variable in the custom [user\_constraint](@ref).

### Meta `relationship classes`

*Meta [Relationship Classes](@ref)* are used for defining [model](@ref)-level settings, like which `temporal blocks` or
`stochastic structures` are active, and what the [model](@ref) [output](@ref) is.
These include:

- [model\_\_default\_investment\_stochastic\_structure](@ref) defines a default [stochastic\_structure](@ref) to be used for investment [Variables](@ref) when no other definitions exist.
- [model\_\_default\_investment\_temporal\_block](@ref) defines a default [temporal\_block](@ref) to be used for investment [Variables](@ref) when no other definitions exist.
- [model\_\_default\_stochastic\_structure](@ref) defines a default [stochastic\_structure](@ref) to be used for `nodes` and `units` when no other definitions exist.
- [model\_\_default\_temporal\_block](@ref) defines a default [temporal\_block](@ref) to be used for `nodes` and `units` when no other definitions exist.
- [model\_\_report](@ref) connects each [report](@ref) to the desired [model](@ref).
- [model\_\_stochastic\_structure](@ref) defines which `stochastic structures` are active in which `models`.
- [model\_\_temporal\_block](@ref) defines which `temporal blocks` are active in which `models`.
- [report\_\_output](@ref) defines which `outputs` are part of which [report](@ref).


## [Introduction to `parameters`](@id introduction-to-parameters)

While the primary function of [Object Classes](@ref) and [Relationship Classes](@ref) is to *define* the system to be
modelled and it's structure, [Parameters](@ref) exist to *constrain* them.
Every `parameter` is attributed to at least one `object class` or `relationship class`, but some appear in many classes
whenever they serve a similar purpose.

[Parameters](@ref) accept different types of values depending on their purpose, e.g. whether they act as a *flag* for
some specific functionality or appear as a *coefficient* in [Constraints](@ref), so understanding each `parameter` is key.
Most coefficient-type [Parameters](@ref) accept *constant*, *time series*, and even *stochastic time series* form input,
but there are some exceptions.
Most *flag-type* [Parameters](@ref), on the other hand, have a restricted list of acceptable values defined by their
[Parameter Value Lists](@ref).

The existence of some [Constraints](@ref) is controlled based on if the relevant [Parameters](@ref) are
defined.
As a rule-of-thumb, a `constraint` only gets generated if at least one of the [Parameters](@ref) appearing in it is
defined, but one should refer to the appropriate [Constraints](@ref) and [Parameters](@ref) sections when in doubt.

## Introduction to groups of objects

Groups of objects are used within SpineOpt for different purposes. To create a group of objects, simply right-click the corresponding
[Object Class](@ref Object-Classes) in the *Spine Toolbox* database editor and select `Add object group`.
Groups are essentially special `objects`, that act as a single handle for all of its members.

On the one hand, groups can be used in order to impose constraints on the aggregation of a variable, e.g. on the sum of multiple [unit\_flow](@ref) variables. Constraints based on parameters associated with the [unit\_\_node\_\_node](@ref), [unit\_\_to\_node](@ref), [node\_\_to\_unit](@ref), [connection\_\_node\_\_node](@ref), [connection\_\_to\_node](@ref), [connection\_\_from\_node](@ref) can generally be used for this kind of flow aggregation by defining the parameters on groups of objects, typically node groups.
(with the exception of variable fixing parameters, e.g. [fix\_unit\_flow](@ref), [fix\_connection\_flow](@ref) etc.). See for instance [constraint\_unit\_flow\_capacity](@ref).

On the other hand, a node group can be used to for [PTDF based powerflows](@ref ptdf-based-powerflow).
Here a node group is used to enforce a nodal balance on system level,
while suppressing the node balances at individual nodes. See also [balance\_type](@ref)
and [the node balance constraint](@ref constraint_nodal_balance).
