# Relationship Classes

## `connection__from_node`

Defines the `nodes` the `connection` can take input from, and holds most `connection_flow` variable specific parameters.

Related [Object Classes](@ref): [connection](@ref) and [node](@ref)

TODO

## `connection__from_node__unit_constraint`

when specified this relationship allows the relevant flow connection flow variable to be included in the specified user constraint

Related [Object Classes](@ref): [connection](@ref), [node](@ref) and [unit\_constraint](@ref)

TODO

## `connection__investment_stochastic_structure`

Defines the stochastic structure of the connections investments variable

Related [Object Classes](@ref): [connection](@ref) and [stochastic\_structure](@ref)

TODO

## `connection__investment_temporal_block`

Defines the temporal resolution of the connections investments variable

Related [Object Classes](@ref): [connection](@ref) and [temporal\_block](@ref)

TODO

## `connection__node__node`

Holds parameters spanning multiple `connection_flow` variables to and from multiple `nodes`.

Related [Object Classes](@ref): [connection](@ref) and [node](@ref)

TODO

## `connection__to_node`

Defines the `nodes` the `connection` can output to, and holds most `connection_flow` variable specific parameters.

Related [Object Classes](@ref): [connection](@ref) and [node](@ref)

TODO

## `connection__to_node__unit_constraint`

when specified this relationship allows the relevant flow connection flow variable to be included in the specified user constraint

Related [Object Classes](@ref): [connection](@ref), [node](@ref) and [unit\_constraint](@ref)

TODO

## `model__default_investment_stochastic_structure`

Defines the default stochastic structure used for investment variables, which will be replaced by more specific definitions

Related [Object Classes](@ref): [model](@ref) and [stochastic\_structure](@ref)

TODO

## `model__default_investment_temporal_block`

Defines the default temporal block used for investment variables, which will be replaced by more specific definitions

Related [Object Classes](@ref): [model](@ref) and [temporal\_block](@ref)

TODO

## `model__default_stochastic_structure`

Defines the default stochastic structure used for model variables, which will be replaced by more specific definitions

Related [Object Classes](@ref): [model](@ref) and [stochastic\_structure](@ref)

TODO

## `model__default_temporal_block`

Defines the default temporal block used for model variables, which will be replaced by more specific definitions

Related [Object Classes](@ref): [model](@ref) and [temporal\_block](@ref)

TODO

## `model__report`

Determines which reports are written for each model and in turn, which outputs are written for each model

Related [Object Classes](@ref): [model](@ref) and [report](@ref)

TODO

## `model__stochastic_structure`

Defines which `stochastic_structure`s are included in which `model`s.

Related [Object Classes](@ref): [model](@ref) and [stochastic\_structure](@ref)

TODO

## `model__temporal_block`

Defines which `temporal_block`s are included in which `model`s.

Related [Object Classes](@ref): [model](@ref) and [temporal\_block](@ref)

TODO

## `node__commodity`

Define a `commodity` for a `node`. Only a single `commodity` is permitted per `node`

Related [Object Classes](@ref): [commodity](@ref) and [node](@ref)

TODO

## `node__investment_stochastic_structure`

defines the stochastic structure for node related investments, currently only storages

Related [Object Classes](@ref): [node](@ref) and [stochastic\_structure](@ref)

TODO

## `node__investment_temporal_block`

defines the temporal resolution for node related investments, currently only storages

Related [Object Classes](@ref): [node](@ref) and [temporal\_block](@ref)

TODO

## `node__node`

Holds parameters for direct interactions between two `nodes`, e.g. `node_state` diffusion coefficients.

Related [Object Classes](@ref): [node](@ref)

TODO

## `node__stochastic_structure`

Defines which specific `stochastic_structure` is used by the `node` and all `flow` variables associated with it. Only one `stochastic_structure` is permitted per `node`.

Related [Object Classes](@ref): [node](@ref) and [stochastic\_structure](@ref)

TODO

## `node__temporal_block`

Defines the `temporal_blocks` used by the `node` and all the `flow` variables associated with it.

Related [Object Classes](@ref): [node](@ref) and [temporal\_block](@ref)

TODO

## `node__unit_constraint`

specifying this relationship allows a node's demand or node_state to be included in the specified unit constraint

Related [Object Classes](@ref): [node](@ref) and [unit\_constraint](@ref)

TODO

## `parent_stochastic_scenario__child_stochastic_scenario`

Defines the master stochastic direct acyclic graph, meaning how the `stochastic_scenarios` are related to each other.

Related [Object Classes](@ref): [stochastic\_scenario](@ref)

The [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationship defines how the individual
[stochastic\_scenario](@ref)s are related to each other, forming what is referred to as the
*stochastic direct acyclic graph (DAG)* in the [Stochastic Framework](@ref) section.
It acts as a sort of basis for the [stochastic\_structure](@ref)s, but doesn't contain any [Parameters](@ref)
necessary for describing how it relates to the [Temporal Framework](@ref) or the [Objective function](@ref).

The [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationship and the *stochastic DAG* it forms
are crucial for [Constraint generation with stochastic path indexing](@ref).
Every finite *stochastic DAG* has a limited number of unique ways of traversing it, called *full stochastic paths*,
which are used when determining how many different constraints need to be generated over time periods where
[stochastic\_structure](@ref)s branch or converge, or when generating constraints involving different
[stochastic\_structure](@ref)s.
See the [Stochastic Framework](@ref) section for more information.

## `report__output`

Output object related to a report object are returned to the output database (if they appear in the model as variables)

Related [Object Classes](@ref): [output](@ref) and [report](@ref)

TODO

## `stochastic_structure__stochastic_scenario`

Defines which `stochastic_scenarios` are included in which `stochastic_structure`, and holds the parameters required for realizing the structure in combination with the `temporal_blocks`.

Related [Object Classes](@ref): [stochastic\_scenario](@ref) and [stochastic\_structure](@ref)

The [stochastic\_structure\_\_stochastic\_scenario](@ref) relationship defines which [stochastic\_scenario](@ref)s
are included in which [stochastic\_structure](@ref), as well as holds the [stochastic\_scenario\_end](@ref) and
[weight\_relative\_to\_parents](@ref) [Parameters](@ref) defining how the [stochastic\_structure](@ref) interacts
with the [Temporal Framework](@ref) and the [Objective function](@ref).
Along with [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref),
this relationship is used to define the exact properties of each [stochastic\_structure](@ref),
which are then applied to the `objects` describing the modelled system according to the
[Structural relationship classes](@ref), like the [node\_\_stochastic\_structure](@ref) relationship.

## `unit__commodity`

Holds parameters for `commodities` used by the `unit`?

Related [Object Classes](@ref): [commodity](@ref) and [unit](@ref)

TODO

## `unit__from_node`

Defines the `nodes` the `unit` can take input from, and holds most `unit_flow` variable specific parameters.

Related [Object Classes](@ref): [node](@ref) and [unit](@ref)

TODO

## `unit__from_node__unit_constraint`

Defines which input `unit_flows` are included in the `unit_constraint`, and holds their parameters?

Related [Object Classes](@ref): [node](@ref), [unit](@ref) and [unit\_constraint](@ref)

TODO

## `unit__investment_stochastic_structure`

Sets the stochastic structure for investment decisions - overrides `model__default_investment_stochastic_structure`. TODO: THIS RELATIONSHIP DOESN'T CURRENTLY APPEAR IN THE MODEL!

Related [Object Classes](@ref): [stochastic\_structure](@ref) and [unit](@ref)

TODO

## `unit__investment_temporal_block`

Sets the temporal resolution of investment decisions - overrides `model__default_investment_temporal_block`

Related [Object Classes](@ref): [temporal\_block](@ref) and [unit](@ref)

TODO

## `unit__node__node`

Holds parameters spanning multiple `unit_flow` variables to and from multiple `nodes`.

Related [Object Classes](@ref): [node](@ref) and [unit](@ref)

TODO

## `unit__to_node`

Defines the `nodes` the `unit` can output to, and holds most `unit_flow` variable specific parameters.

Related [Object Classes](@ref): [node](@ref) and [unit](@ref)

TODO

## `unit__to_node__unit_constraint`

Defines which output `unit_flows` are included in the `unit_constraint`, and holds their parameters?

Related [Object Classes](@ref): [node](@ref), [unit](@ref) and [unit\_constraint](@ref)

TODO

## `unit__unit_constraint`

Defines which `units_on` variables are included in the `unit_constraint`, and holds their parameters?

Related [Object Classes](@ref): [unit](@ref) and [unit\_constraint](@ref)

TODO

## `units_on__stochastic_structure`

Defines which specific `stochastic_structure` is used for the `units_on` variable of the `unit`. Only one `stocahstic_structure` is permitted per `unit`.

Related [Object Classes](@ref): [stochastic\_structure](@ref) and [unit](@ref)

TODO

## `units_on__temporal_block`

Defines which specific `temporal_blocks` are used by the `units_on` variable of the `unit`.

Related [Object Classes](@ref): [temporal\_block](@ref) and [unit](@ref)

TODO

