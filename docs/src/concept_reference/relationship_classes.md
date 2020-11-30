# Relationship Classes

TODO: Briefly explain what `RelationshipClasses` are, and what they represent in *SpineOpt*.


## `model__temporal_block`

**Relates object classes:** `model,temporal_block`

TODO

## `connection__from_node`

**Relates object classes:** `connection,node`

Defines the `nodes` the `connection` can take input from, and holds most `connection_flow` variable specific parameters.

## `connection__node__node`

**Relates object classes:** `connection,node,node`

Holds parameters spanning multiple `connection_flow` variables to and from multiple `nodes`.

## `connection__to_node`

**Relates object classes:** `connection,node`

Defines the `nodes` the `connection` can output to, and holds most `connection_flow` variable specific parameters.

## `model__default_stochastic_structure`

**Relates object classes:** `model,stochastic_structure`

Defines the default stochastic structure used for model variables, which will be replaced by more specific definitions

## `model__default_temporal_block`

**Relates object classes:** `model,temporal_block`

Defines the default temporal block used for model variables, which will be replaced by more specific definitions

## `model__default_investment_stochastic_structure`

**Relates object classes:** `model,stochastic_structure`

Defines the default stochastic structure used for investment variables, which will be replaced by more specific definitions

## `model__default_investment_temporal_block`

**Relates object classes:** `model,temporal_block`

Defines the default temporal block used for investment variables, which will be replaced by more specific definitions

## `node__commodity`

**Relates object classes:** `node,commodity`

Define a `commodity` for a `node`. Only a single `commodity` is permitted per `node`

## `node__node`

**Relates object classes:** `node,node`

Holds parameters for direct interactions between two `nodes`, e.g. `node_state` diffusion coefficients.

## `node__stochastic_structure`

**Relates object classes:** `node,stochastic_structure`

Defines which specific `stochastic_structure` is used by the `node` and all `flow` variables associated with it. Only one `stochastic_structure` is permitted per `node`.

## `node__temporal_block`

**Relates object classes:** `node,temporal_block`

Defines the `temporal_blocks` used by the `node` and all the `flow` variables associated with it.

## `parent_stochastic_scenario__child_stochastic_scenario`

**Relates object classes:** `stochastic_scenario,stochastic_scenario`

Defines the master stochastic direct acyclic graph, meaning how the `stochastic_scenarios` are related to each other.

## `report__output`

**Relates object classes:** `report,output`

Output object related to a report object are returned to the output database (if they appear in the model as variables)

## `stochastic_structure__stochastic_scenario`

**Relates object classes:** `stochastic_structure,stochastic_scenario`

Defines which `stochastic_scenarios` are included in which `stochastic_structure`, and holds the parameters required for realizing the structure in combination with the `temporal_blocks`.

## `unit__from_node`

**Relates object classes:** `unit,node`

Defines the `nodes` the `unit` can take input from, and holds most `unit_flow` variable specific parameters.

## `unit__from_node__unit_constraint`

**Relates object classes:** `unit,node,unit_constraint`

Defines which input `unit_flows` are included in the `unit_constraint`, and holds their parameters?

## `unit__node__node`

**Relates object classes:** `unit,node,node`

Holds parameters spanning multiple `unit_flow` variables to and from multiple `nodes`.

## `unit__commodity`

**Relates object classes:** `unit,commodity`

Holds parameters for `commodities` used by the `unit`?

## `units_on__stochastic_structure`

**Relates object classes:** `unit,stochastic_structure`

Defines which specific `stochastic_structure` is used for the `units_on` variable of the `unit`. Only one `stocahstic_structure` is permitted per `unit`.

## `units_on__temporal_block`

**Relates object classes:** `unit,temporal_block`

Defines which specific `temporal_blocks` are used by the `units_on` variable of the `unit`.

## `unit__investment_stochastic_structure`

**Relates object classes:** `unit,stochastic_structure`

Sets the stochastic structure for investment decisions - overrides `model__default_investment_stochastic_structure`. TODO: THIS RELATIONSHIP DOESN'T CURRENTLY APPEAR IN THE MODEL!

## `unit__investment_temporal_block`

**Relates object classes:** `unit,temporal_block`

Sets the temporal resolution of investment decisions - overrides `model__default_investment_temporal_block`

## `unit__to_node`

**Relates object classes:** `unit,node`

Defines the `nodes` the `unit` can output to, and holds most `unit_flow` variable specific parameters.

## `unit__to_node__unit_constraint`

**Relates object classes:** `unit,node,unit_constraint`

Defines which output `unit_flows` are included in the `unit_constraint`, and holds their parameters?

## `unit__unit_constraint`

**Relates object classes:** `unit,unit_constraint`

Defines which `units_on` variables are included in the `unit_constraint`, and holds their parameters?
