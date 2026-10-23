# Basics of the model structure

In *SpineOpt.jl*, the model structure is generated based on the input data, allowing it to be used for a multitude of
different problems.
Here, we aim to provide you with a basic understanding of the *SpineOpt.jl* model and data structure, while the
[Entity Classes](@ref), [Parameters](@ref), and [Parameter Value Lists](@ref) sections
provide more in-depth explanations of each concept.

All the building blocks of a model are *entities*, and each entity belongs to one of the [Entity Classes](@ref).
Zero-dimensional entity classes, such as [unit](@ref) or [node](@ref), hold the individual things in the model.
Multi-dimensional entity classes, such as [unit\_\_to\_node](@ref), combine two or more entity classes and define how
their entities are related to each other.
The dimensions of a multi-dimensional entity class are separated by a double underscore in its name.
In the *Spine DB editor*, both kinds are shown in the *Entity tree* and created with *Add entities...*.

!!! note
    Older versions of Spine Toolbox and SpineOpt called zero-dimensional entity classes `object classes` and
    multi-dimensional entity classes `relationship classes`. You may still come across these terms in older material.


## [Introduction to zero-dimensional entity classes](@id introduction-to-object-classes)

Essentially, zero-dimensional [Entity Classes](@ref) represent different types of entities that make up the model.
For example, every power plant in the model is represented as an entity of the class [unit](@ref),
every power line as an entity of the class [connection](@ref), and so forth.
In order to add anything new to a model, a new entity has to be added to the desired entity class in the input data.

Each entity class has a very specific purpose in *SpineOpt.jl*, so understanding their differences is key.
These can be roughly divided into three distinctive groups, namely [Systemic entity classes](@ref),
[Structural entity classes](@ref), and [Meta entity classes](@ref).

### Systemic entity classes

As the name implies, *systemic entity classes* are used to describe the system to be modelled.
Essentially, they define *what* you want to model.
These include:

- [connection](@ref) handles the transfer of commodities between [node](@ref)s.
- [grid](@ref) represents different networks where different commodities can be generated, consumed, transported, etc.
- [node](@ref) ensures the balance of the commodity flows, and can be used to store commodities as well.
- [unit](@ref) handles the generation and consumption of commodities.

### Structural entity classes

*Structural entity classes* are used to define the temporal and stochastic structure of the modelled problem, as
well as custom [User Constraints](@ref) and groups of investments.
Unlike the above [Systemic entity classes](@ref), the *structural entity classes* are more about *how* you
want to model, instead of strictly *what* you want to model.
These include:

- [investment\_group](@ref) is a group of investments that need to be done together.
- [stochastic\_scenario](@ref) represents a different *forecast* or another type of an *alternative time period*.
- [stochastic\_structure](@ref) acts as a handle for a group of [stochastic\_scenario](@ref)s with set properties.
- [temporal\_block](@ref) defines a period of *time* with the desired temporal [resolution](@ref).
- [user\_constraint](@ref) is an optional custom constraint generated based on the input data.

### Meta entity classes

*Meta entity classes* are used for defining things on the level of [model](@ref)s or above, like
[output](@ref) and even other [model](@ref)s for problem decompositions.
These include:

- [model](@ref) represents an individual *model*, grouping together all the things relevant for itself.
- [output](@ref) defines which [Variables](@ref) are output from the [model](@ref).
- [report](@ref) groups together multiple [output](@ref) entities.
- [settings](@ref) holds internal SpineOpt settings, which normally do not need to be changed.
- [stage](@ref) defines an additional stage in the optimisation problem, see the [Multi-Stage Optimisation Tutorial](@ref) (experimental).


## [Introduction to multi-dimensional entity classes](@id introduction-to-relationship-classes)

While zero-dimensional entity classes define all the entities that make up a [model](@ref),
multi-dimensional [Entity Classes](@ref) define how those entities are related to each other.
Thus, they hold no meaning on their own, and always include at least one zero-dimensional entity class.

Similar to zero-dimensional entity classes, each multi-dimensional entity class has a very specific purpose in
*SpineOpt.jl*, and understanding the purpose of each one is paramount.
The multi-dimensional entity classes can be roughly divided into [Systemic multi-dimensional entity classes](@ref),
[Structural multi-dimensional entity classes](@ref), and [Meta multi-dimensional entity classes](@ref),
again similar to the zero-dimensional ones.

### Systemic multi-dimensional entity classes

*Systemic multi-dimensional entity classes* define how [Systemic entity classes](@ref) are related to each other,
thus helping define the system to be modelled.
Most of these deal with *which* [unit](@ref)s and [connection](@ref)s interact with *which* [node](@ref)s, and *how* those
interactions work.
This essentially defines the possible commodity flows to be modelled.
*Systemic multi-dimensional entity classes* include:

- [connection\_\_from\_node](@ref) defines which [node](@ref) the [connection](@ref) can transfer a commodity from.
- [connection\_\_to\_node](@ref) defines which [node](@ref) the [connection](@ref) can transfer a commodity to.
- [connection\_\_node\_\_node](@ref) holds [Parameters](@ref) for [connection](@ref)s between two [node](@ref)s.
- [node\_\_grid](@ref) defines which [node](@ref) is part of which [grid](@ref).
- [node\_\_node](@ref) holds parameters for direct [node](@ref)-[node](@ref) interactions, like diffusion of commodities.
- [node\_\_to\_unit](@ref) defines which [node](@ref) the [unit](@ref) can take an input commodity from.
- [unit\_\_to\_node](@ref) defines which [node](@ref) the [unit](@ref) can output a commodity to.
- [unit\_flow](@ref) is a superclass of [node\_\_to\_unit](@ref) and [unit\_\_to\_node](@ref), i.e. it covers the flows in both directions. It is used as a dimension in other entity classes, such as [unit\_flow\_\_unit\_flow](@ref).
- [unit\_flow\_\_unit\_flow](@ref) defines parameters between [node\_\_to\_unit](@ref) and [unit\_\_to\_node](@ref) flows.

### Structural multi-dimensional entity classes

*Structural multi-dimensional entity classes* primarily relate [Structural entity classes](@ref) to
[Systemic entity classes](@ref), defining what *structures* the individual parts of the *system* use.
These are mostly used to determine the temporal and stochastic structures to be used in different parts of the
modelled *system*, or custom [User Constraints](@ref).

*SpineOpt.jl* has a very flexible temporal and stochastic structure, explained in detail in the
[Temporal Framework](@ref) and [Stochastic Framework](@ref stochastic_framework) sections of the documentation.
Unfortunately, this flexibility requires quite a few different *structural multi-dimensional entity classes*,
the most important of which are the following:

- [node\_\_stochastic\_structure](@ref) defines the [stochastic\_structure](@ref) used for the [node](@ref) balance.
- [node\_\_temporal\_block](@ref) defines the [temporal\_block](@ref)s used for the [node](@ref) balance.
- [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) defines the *stochastic directed acyclic graph (DAG)* of the [Stochastic Framework](@ref stochastic_framework).
- [stochastic\_structure\_\_stochastic\_scenario](@ref) holds parameters for [stochastic\_scenario](@ref)s in the [stochastic\_structure](@ref).
- [units\_on\_\_stochastic\_structure](@ref) defines the [stochastic\_structure](@ref) used for the online variable of the [unit](@ref).
- [units\_on\_\_temporal\_block](@ref) defines the [temporal\_block](@ref)s used for the online variable of the [unit](@ref).

Furthermore, there are also a number of *advanced structural multi-dimensional entity classes*, which are only
necessary when using some of the optional features of *SpineOpt.jl*.
For [Investment Optimization](@ref), the following control the stochastic and temporal structures
of the investment [variables](@ref Variables):

- [connection\_\_investment\_stochastic\_structure](@ref) defines the [stochastic\_structure](@ref) used for the investment [Variables](@ref) for the [connection](@ref).
- [connection\_\_investment\_temporal\_block](@ref) defines the [temporal\_block](@ref)s used for the investment [Variables](@ref) for the [connection](@ref).
- [node\_\_investment\_stochastic\_structure](@ref) defines the [stochastic\_structure](@ref) used for the investment [Variables](@ref) for the [node](@ref).
- [node\_\_investment\_temporal\_block](@ref) defines the [temporal\_block](@ref)s used for the investment [Variables](@ref) for the [node](@ref).
- [unit\_\_investment\_stochastic\_structure](@ref) defines the [stochastic\_structure](@ref) used for the investment [Variables](@ref) for the [unit](@ref).
- [unit\_\_investment\_temporal\_block](@ref) defines the [temporal\_block](@ref)s used for the investment [Variables](@ref) for the [unit](@ref).

The following define which investments belong to an [investment\_group](@ref):

- [connection\_\_investment\_group](@ref) defines a [connection](@ref) that belongs in an [investment\_group](@ref).
- [node\_\_investment\_group](@ref) defines a [node](@ref) that belongs in an [investment\_group](@ref).
- [unit\_\_investment\_group](@ref) defines a [unit](@ref) that belongs in an [investment\_group](@ref).
- [connection\_\_from\_node\_\_investment\_group](@ref) and [connection\_\_to\_node\_\_investment\_group](@ref) define a flow on a [connection](@ref) whose capacity is counted in the capacity invested available of an [investment\_group](@ref).
- [unit\_flow\_\_investment\_group](@ref) defines a flow on a [unit](@ref) whose capacity is counted in the capacity invested available of an [investment\_group](@ref).

For [User Constraints](@ref), which are essentially generic data-driven custom constraints,
the following are used to control which [variables](@ref Variables) are included and with what coefficients:  

- [connection\_\_from\_node\_\_user\_constraint](@ref) holds [Parameters](@ref) for the [connection\_flow](@ref var_connection_flow) variable *from* the [node](@ref) in question in the custom [user\_constraint](@ref).
- [connection\_\_to\_node\_\_user\_constraint](@ref) holds [Parameters](@ref) for the [connection\_flow](@ref var_connection_flow) variable *to* the [node](@ref) in question in the custom [user\_constraint](@ref).
- [connection\_\_user\_constraint](@ref) holds [Parameters](@ref) for the investment [Variables](@ref) of the [connection](@ref) in the custom [user\_constraint](@ref).
- [node\_\_user\_constraint](@ref) holds [Parameters](@ref) for the [node\_state](@ref var_node_state) variable or the [demand](@ref) of the [node](@ref) in the custom [user\_constraint](@ref).
- [unit\_\_user\_constraint](@ref) holds [Parameters](@ref) for the unit commitment [Variables](@ref) of the [unit](@ref) in the custom [user\_constraint](@ref).
- [unit\_flow\_\_user\_constraint](@ref) holds [Parameters](@ref) for the [unit\_flow](@ref var_unit_flow) variable in the custom [user\_constraint](@ref).

### Meta multi-dimensional entity classes

*Meta multi-dimensional entity classes* are used for defining [model](@ref)-level settings, like which [temporal\_block](@ref)s or
[stochastic\_structure](@ref)s are active, and what the [model](@ref) [output](@ref) is.
These include:

- [model\_\_default\_investment\_stochastic\_structure](@ref) defines a default [stochastic\_structure](@ref) to be used for investment [Variables](@ref) when no other definitions exist.
- [model\_\_default\_investment\_temporal\_block](@ref) defines a default [temporal\_block](@ref) to be used for investment [Variables](@ref) when no other definitions exist.
- [model\_\_default\_stochastic\_structure](@ref) defines a default [stochastic\_structure](@ref) to be used for [node](@ref)s and [unit](@ref)s when no other definitions exist.
- [model\_\_default\_temporal\_block](@ref) defines a default [temporal\_block](@ref) to be used for [node](@ref)s and [unit](@ref)s when no other definitions exist.
- [model\_\_report](@ref) connects each [report](@ref) to the desired [model](@ref).
- [report\_\_output](@ref) defines which [output](@ref)s are part of which [report](@ref).

For the experimental multi-stage optimisation (see the [Multi-Stage Optimisation Tutorial](@ref)):

- [stage\_\_child\_stage](@ref) defines a parent-child relationship between two [stage](@ref)s.
- [stage\_\_output](@ref) defines an [output](@ref) that a [stage](@ref) fixes for all entities in all its children.
- [stage\_\_output\_\_connection](@ref), [stage\_\_output\_\_node](@ref) and [stage\_\_output\_\_unit](@ref) define an [output](@ref) that a [stage](@ref) fixes for a specific [connection](@ref), [node](@ref) or [unit](@ref) in all its children.


## [Introduction to `parameters`](@id introduction-to-parameters)

While the primary function of [Entity Classes](@ref) is to *define* the system to be
modelled and its structure, [Parameters](@ref) exist to *constrain* them.
Every `parameter` is attributed to at least one entity class, but some appear in many classes
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

## [Introduction to groups of entities](@id Introduction-to-groups-of-objects)

Groups of entities are used within SpineOpt for different purposes. To create a group of entities, simply right-click the corresponding
entity class in the *Entity tree* of the *Spine DB editor* and select *Add entity group...*.
Groups are essentially special entities, that act as a single handle for all of their members.

On the one hand, groups can be used in order to impose constraints on the aggregation of a variable, e.g. on the sum of multiple [unit\_flow variables](@ref var_unit_flow). Constraints based on parameters associated with the [unit\_flow\_\_unit\_flow](@ref), [unit\_\_to\_node](@ref), [node\_\_to\_unit](@ref), [connection\_\_node\_\_node](@ref), [connection\_\_to\_node](@ref), [connection\_\_from\_node](@ref) can generally be used for this kind of flow aggregation by defining the parameters on groups of entities, typically node groups.
(with the exception of variable fixing parameters, e.g. [flow\_limits\_fix](@ref) etc.). See for instance [constraint\_unit\_flow\_capacity](@ref).

On the other hand, a node group can be used for [PTDF based powerflows](@ref ptdf-based-powerflow).
Here a node group is used to enforce a nodal balance on system level,
while suppressing the node balances at individual nodes. See also [balance\_type](@ref)
and [the node balance constraint](@ref constraint_nodal_balance).
