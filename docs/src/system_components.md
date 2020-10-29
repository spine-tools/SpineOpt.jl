# System Components

## object_classes

### `commodity`

A good or product that can be consumed, produced, traded. E.g., electricity, oil, gas, water...

### `connection`

A transfer of commodities between nodes. E.g. electricity line, gas pipeline...

### `model`

An instance of SpineOpt, that specifies general parameters such as the temporal horizon.

### `node`

A universal aggregator of commodify flows over units and connections, with storage capabilities.

### `output`

A variable name from SpineOpt that can be included in a report.

### `report`

A results report from a particular SpineOpt run, including the value of specific variables.

### `stochastic_scenario`

A scenario for stochastic optimisation in SpineOpt.

### `stochastic_structure`

A group of stochastic scenarios that represent a structure.

### `temporal_block`

A length of time with a particular resolution.

### `unit`

A conversion of one/many comodities between nodes.

### `unit_constraint`

A constraint over the flows of a specific unit.

## relationship_classes

### `model__temporal_block`

**Relates object classes:** `model,temporal_block`

TODO

### `connection__from_node`

**Relates object classes:** `connection,node`

Defines the `nodes` the `connection` can take input from, and holds most `connection_flow` variable specific parameters.

### `connection__node__node`

**Relates object classes:** `connection,node,node`

Holds parameters spanning multiple `connection_flow` variables to and from multiple `nodes`.

### `connection__to_node`

**Relates object classes:** `connection,node`

Defines the `nodes` the `connection` can output to, and holds most `connection_flow` variable specific parameters.

### `model__default_stochastic_structure`

**Relates object classes:** `model,stochastic_structure`

Defines the default stochastic structure used for model variables, which will be replaced by more specific definitions

### `model__default_temporal_block`

**Relates object classes:** `model,temporal_block`

Defines the default temporal block used for model variables, which will be replaced by more specific definitions

### `model__default_investment_stochastic_structure`

**Relates object classes:** `model,stochastic_structure`

Defines the default stochastic structure used for investment variables, which will be replaced by more specific definitions

### `model__default_investment_temporal_block`

**Relates object classes:** `model,temporal_block`

Defines the default temporal block used for investment variables, which will be replaced by more specific definitions

### `node__commodity`

**Relates object classes:** `node,commodity`

Define a `commodity` for a `node`. Only a single `commodity` is permitted per `node`

### `node__node`

**Relates object classes:** `node,node`

Holds parameters for direct interactions between two `nodes`, e.g. `node_state` diffusion coefficients.

### `node__stochastic_structure`

**Relates object classes:** `node,stochastic_structure`

Defines which specific `stochastic_structure` is used by the `node` and all `flow` variables associated with it. Only one `stochastic_structure` is permitted per `node`.

### `node__temporal_block`

**Relates object classes:** `node,temporal_block`

Defines the `temporal_blocks` used by the `node` and all the `flow` variables associated with it.

### `parent_stochastic_scenario__child_stochastic_scenario`

**Relates object classes:** `stochastic_scenario,stochastic_scenario`

Defines the master stochastic direct acyclic graph, meaning how the `stochastic_scenarios` are related to each other.

### `report__output`

**Relates object classes:** `report,output`

Output object related to a report object are returned to the output database (if they appear in the model as variables)

### `stochastic_structure__stochastic_scenario`

**Relates object classes:** `stochastic_structure,stochastic_scenario`

Defines which `stochastic_scenarios` are included in which `stochastic_structure`, and holds the parameters required for realizing the structure in combination with the `temporal_blocks`.

### `unit__from_node`

**Relates object classes:** `unit,node`

Defines the `nodes` the `unit` can take input from, and holds most `unit_flow` variable specific parameters.

### `unit__from_node__unit_constraint`

**Relates object classes:** `unit,node,unit_constraint`

Defines which input `unit_flows` are included in the `unit_constraint`, and holds their parameters?

### `unit__node__node`

**Relates object classes:** `unit,node,node`

Holds parameters spanning multiple `unit_flow` variables to and from multiple `nodes`.

### `unit__commodity`

**Relates object classes:** `unit,commodity`

Holds parameters for `commodities` used by the `unit`?

### `units_on__stochastic_structure`

**Relates object classes:** `unit,stochastic_structure`

Defines which specific `stochastic_structure` is used for the `units_on` variable of the `unit`. Only one `stocahstic_structure` is permitted per `unit`.

### `units_on__temporal_block`

**Relates object classes:** `unit,temporal_block`

Defines which specific `temporal_blocks` are used by the `units_on` variable of the `unit`.

### `unit__investment_stochastic_structure`

**Relates object classes:** `unit,stochastic_structure`

Sets the stochastic structure for investment decisions - overrides `model__default_investment_stochastic_structure`. TODO: THIS RELATIONSHIP DOESN'T CURRENTLY APPEAR IN THE MODEL!

### `unit__investment_temporal_block`

**Relates object classes:** `unit,temporal_block`

Sets the temporal resolution of investment decisions - overrides `model__default_investment_temporal_block`

### `unit__to_node`

**Relates object classes:** `unit,node`

Defines the `nodes` the `unit` can output to, and holds most `unit_flow` variable specific parameters.

### `unit__to_node__unit_constraint`

**Relates object classes:** `unit,node,unit_constraint`

Defines which output `unit_flows` are included in the `unit_constraint`, and holds their parameters?

### `unit__unit_constraint`

**Relates object classes:** `unit,unit_constraint`

Defines which `units_on` variables are included in the `unit_constraint`, and holds their parameters?

## object_parameters

### `commodity_lodf_tolerance`

**Object class:** [`commodity`](#commodity)

**Default value:** `0.1`

LODF tolerance?

### `commodity_physics`

**Object class:** [`commodity`](#commodity)

**Default value:** `commodity_physics_none`

**Parameter value list:** [`commodity_physics_list`](#commodity_physics_list)

Defines if the `commodity` follows lodf or ptdf physics.

### `commodity_ptdf_threshold`

**Object class:** [`commodity`](#commodity)

**Default value:** `0.0001`

PTDF threshold?

### `connection_availability_factor`

**Object class:** [`connection`](#connection)

**Default value:** `1.0`

Availability of the `connection`, acting as a multiplier on its `connection_capacity`. Typically between 0-1.

### `connection_contingency`

**Object class:** [`connection`](#connection)

**Parameter value list:** [`boolean_value_list`](#boolean_value_list)

A boolean flag for defining a contingency `connection`.

### `connection_flow_cost`

**Object class:** [`connection`](#connection)

Variable costs of a flow through a `connection`. E.g. EUR/MWh of energy throughput.

### `connection_monitored`

**Object class:** [`connection`](#connection)

**Default value:** `false`

**Parameter value list:** [`boolean_value_list`](#boolean_value_list)

A boolean flag for defining a contingency `connection`.

### `connection_reactance`

**Object class:** [`connection`](#connection)

Reactance of a `connection`.

### `connection_resistance`

**Object class:** [`connection`](#connection)

Resistance of a `connection`.

### `connection_type`

**Object class:** [`connection`](#connection)

**Default value:** `connection_type_normal`

**Parameter value list:** [`connection_type_list`](#connection_type_list)

A selector between a normal and a lossless bidirectional `connection`.

### `graph_view_position`

**Object class:** [`connection`](#connection)

### `duration_unit`

**Object class:** [`model`](#model)

**Default value:** `minute`

**Parameter value list:** [`duration_unit_list`](#duration_unit_list)

Defines the base temporal unit of the `model`. Currently supported values are either an `hour` or a `minute`.

### `model_end`

**Object class:** [`model`](#model)

**Default value:** `Dict{String,Any}("data" => "2000-01-02T00:00:00","type" => "date_time")`

Defines the last timestamp to be modelled. Rolling optimization terminates after passing this point.

### `model_start`

**Object class:** [`model`](#model)

**Default value:** `Dict{String,Any}("data" => "2000-01-01T00:00:00","type" => "date_time")`

Defines the first timestamp to be modelled. Relative `temporal_blocks` refer to this value for their start and end.

### `roll_forward`

**Object class:** [`model`](#model)

Defines how much the model moves ahead in time between solves in a rolling optimization. Without this parameter, everything is solved in as a single optimization.

### `write_lodf_file`

**Object class:** [`model`](#model)

**Default value:** `false`

**Parameter value list:** [`boolean_value_list`](#boolean_value_list)

A boolean flag for whether the LODF values should be written to a results file.

### `write_mps_file`

**Object class:** [`model`](#model)

**Parameter value list:** [`write_mps_file_list`](#write_mps_file_list)

A selector for writing an .mps file of the model.

### `write_ptdf_file`

**Object class:** [`model`](#model)

**Default value:** `false`

**Parameter value list:** [`boolean_value_list`](#boolean_value_list)

A boolean flag for whether the LODF values should be written to a results file.

### `balance_type`

**Object class:** [`node`](#node)

**Default value:** `balance_type_node`

**Parameter value list:** [`balance_type_list`](#balance_type_list)

A selector for how the `:nodal_balance` constraint should be handled.

### `demand`

**Object class:** [`node`](#node)

**Default value:** `0.0`

Demand for the `commodity` of a `node`. Energy gains can be represented using negative `demand`.

### `fix_node_state`

**Object class:** [`node`](#node)

Fixes the corresponding `node_state` variable to the provided value. Can be used for e.g. fixing boundary conditions.

### `frac_state_loss`

**Object class:** [`node`](#node)

**Default value:** `0.0`

Self-discharge coefficient for `node_state` variables. Effectively, represents the *loss power per unit of state*.

### `graph_view_position`

**Object class:** [`node`](#node)

### `has_state`

**Object class:** [`node`](#node)

**Default value:** `false`

**Parameter value list:** [`boolean_value_list`](#boolean_value_list)

A boolean flag for whether a `node` has a `node_state` variable.

### `is_reserve_node`

**Object class:** [`node`](#node)

**Default value:** `false`

**Parameter value list:** [`boolean_value_list`](#boolean_value_list)

A boolean flag for a `reserve_node`?

### `minimum_reserve_activation_time`

**Object class:** [`node`](#node)

Duration a certain reserve product needs to be online/available

### `nodal_balance_sense`

**Object class:** [`node`](#node)

**Default value:** `==`

**Parameter value list:** [`constraint_sense`](#constraint_sense)

A selector for `nodal_balance` constraint sense.

### `node_opf_type`

**Object class:** [`node`](#node)

**Default value:** `node_opf_type_normal`

**Parameter value list:** [`node_opf_type_list`](#node_opf_type_list)

A selector for `node_opf_type`?

### `node_slack_penalty`

**Object class:** [`node`](#node)

A penalty cost for `node_slack_pos` and `node_slack_neg` variables. The slack variables won't be included in the model unless there's a cost defined for them.

### `node_state_cap`

**Object class:** [`node`](#node)

The maximum permitted value for a `node_state` variable.

### `node_state_min`

**Object class:** [`node`](#node)

**Default value:** `0.0`

The minimum permitted value for a `node_state` variable.

### `reserve_procurement_cost`

**Object class:** [`node`](#node)

Procurement cost for reserves?

### `state_coeff`

**Object class:** [`node`](#node)

**Default value:** `0.0`

Represents the `commodity` content of a `node_state` variable in respect to the `unit_flow` and `connection_flow` variables. Essentially, acts as a coefficient on the `node_state` variable in the `:node_injection` constraint.

### `tax_in_unit_flow`

**Object class:** [`node`](#node)

**Default value:** `0.0`

Tax costs for incoming `unit_flows` on this `node`. E.g. EUR/MWh.

### `tax_net_unit_flow`

**Object class:** [`node`](#node)

**Default value:** `0.0`

Tax costs for net incoming and outgoing `unit_flows` on this `node`. Incoming flows accrue positive net taxes, and outgoing flows accrue negative net taxes.

### `tax_out_unit_flow`

**Object class:** [`node`](#node)

**Default value:** `0.0`

Tax costs for outgoing `unit_flows` from this `node`. E.g. EUR/MWh.

### `fractional_demand`

**Object class:** [`node`](#node)

**Default value:** `0.0`

Fractional `demand` for `node` groups?

### `output_db_url`

**Object class:** [`report`](#report)

Database url for SpineOpt output.

### `block_end`

**Object class:** [`temporal_block`](#temporal_block)

The end time for the `temporal_block`. Can be given either as a `DateTime` for a static end point, or as a `Duration` for an end point relative to the start of the current optimization.

### `block_start`

**Object class:** [`temporal_block`](#temporal_block)

The start time for the `temporal_block`. Can be given either as a `DateTime` for a static start point, or as a `Duration` for an start point relative to the start of the current optimization.

### `resolution`

**Object class:** [`temporal_block`](#temporal_block)

**Default value:** `Dict{String,Any}("data" => "1h","type" => "duration")`

Temporal resolution of the `temporal_block`. Essentially, divides the period between `block_start` and `block_end` into `TimeSlices` with the input `resolution`.

### `candidate_units`

**Object class:** [`unit`](#unit)

Number of units which may be additionally constructed

### `curtailment_cost`

**Object class:** [`unit`](#unit)

Costs for curtailing generation. Essentially, accrues costs whenever `unit_flow` not operating at its maximum available capacity. E.g. EUR/MWh

### `fix_units_invested`

**Object class:** [`unit`](#unit)

Fix the value of the `units_invested` variable.

### `fix_units_invested_available`

**Object class:** [`unit`](#unit)

Fix the value of the `units_invested_available` variable

### `fix_units_on`

**Object class:** [`unit`](#unit)

Fix the value of the `units_on` variable.

### `fom_cost`

**Object class:** [`unit`](#unit)

Fixed operation and maintenance costs of a `unit`. Essentially, a cost coefficient on the `number_of_units` and `unit_capacity` parameters. E.g. EUR/MWh

### `graph_view_position`

**Object class:** [`unit`](#unit)

### `min_down_time`

**Object class:** [`unit`](#unit)

Minimum downtime of a `unit` after it shuts down.

### `min_up_time`

**Object class:** [`unit`](#unit)

Minimum uptime of a `unit` after it starts up.

### `number_of_units`

**Object class:** [`unit`](#unit)

**Default value:** `1.0`

Denotes the number of 'sub units' aggregated to form the modelled `unit`.

### `online_variable_type`

**Object class:** [`unit`](#unit)

**Default value:** `unit_online_variable_type_linear`

**Parameter value list:** [`unit_online_variable_type_list`](#unit_online_variable_type_list)

A selector for how the `units_on` variable is represented within the model.

### `shut_down_cost`

**Object class:** [`unit`](#unit)

Costs of shutting down a 'sub unit', e.g. EUR/shutdown.

### `start_up_cost`

**Object class:** [`unit`](#unit)

Costs of starting up a 'sub unit', e.g. EUR/startup.

### `unit_availability_factor`

**Object class:** [`unit`](#unit)

**Default value:** `1.0`

Availability of the `unit`, acting as a multiplier on its `unit_capacity`. Typically between 0-1.

### `unit_investment_cost`

**Object class:** [`unit`](#unit)

Investment cost per 'sub unit' built.

### `unit_investment_lifetime`

**Object class:** [`unit`](#unit)

Minimum lifetime for investment decisions.

### `unit_investment_variable_type`

**Object class:** [`unit`](#unit)

**Default value:** `unit_investment_variable_type_continuous`

**Parameter value list:** [`unit_investment_variable_type_list`](#unit_investment_variable_type_list)

Determines whether investment variable is integer or continuous.

### `constraint_sense`

**Object class:** [`unit_constraint`](#unit_constraint)

**Default value:** `==`

**Parameter value list:** [`constraint_sense_list`](#constraint_sense_list)

A selector for the sense of the `unit_constraint`.

### `right_hand_side`

**Object class:** [`unit_constraint`](#unit_constraint)

**Default value:** `0.0`

The right-hand side of the `unit_constraint`. Can be used e.g. for complicated time-dependent efficiency approximations.

## relationship_parameters

### `connection_capacity`

**Relationship class**: [`connection__from_node`](#connection__from_node)

Limits the `connection_flow` variable from the `from_node`. `from_node` can be a group of `nodes`, in which case the sum of the `connection_flow` is constrained.

### `connection_conv_cap_to_flow`

**Relationship class**: [`connection__from_node`](#connection__from_node)

**Default value**: `1.0`

Optional coefficient for `connection_capacity` unit conversions in the case the `connection_capacity` value is incompatible with the desired `connection_flow` units.

### `connection_emergency_capacity`

**Relationship class**: [`connection__from_node`](#connection__from_node)

Emergy capacity of a `connection`?

### `fix_connection_flow`

**Relationship class**: [`connection__from_node`](#connection__from_node)

Fix the value of the `connection_flow` variable.

### `graph_view_position`

**Relationship class**: [`connection__from_node`](#connection__from_node)

### `connection_flow_delay`

**Relationship class**: [`connection__node__node`](#connection__node__node)

**Default value**: `Dict{String,Any}("data" => "0h","type" => "duration")`

Delays the `connection_flows` associated with the latter `node` in respect to the `connection_flows` associated with the first `node`.

### `fix_ratio_out_in_connection_flow`

**Relationship class**: [`connection__node__node`](#connection__node__node)

Fix the ratio between the `connection_flow` from the first `node` and the `connection_flow` to the second `node`.

### `max_ratio_out_in_connection_flow`

**Relationship class**: [`connection__node__node`](#connection__node__node)

Maximum ratio between the `connection_flow` from the first `node` and the `connection_flow` to the second `node`.

### `min_ratio_out_in_connection_flow`

**Relationship class**: [`connection__node__node`](#connection__node__node)

Minimum ratio between the `connection_flow` from the first `node` and the `connection_flow` to the second `node`.

### `connection_capacity`

**Relationship class**: [`connection__to_node`](#connection__to_node)

Limits the `connection_flow` variable to the `to_node`. `to_node` can be a group of `nodes`, in which case the sum of the `connection_flow` is constrained.

### `connection_conv_cap_to_flow`

**Relationship class**: [`connection__to_node`](#connection__to_node)

**Default value**: `1.0`

Optional coefficient for `connection_capacity` unit conversions in the case the `connection_capacity` value is incompatible with the desired `connection_flow` units.

### `connection_emergency_capacity`

**Relationship class**: [`connection__to_node`](#connection__to_node)

Emergy capacity of a `connection`?

### `fix_connection_flow`

**Relationship class**: [`connection__to_node`](#connection__to_node)

Fix the value of the `connection_flow` variable.

### `graph_view_position`

**Relationship class**: [`connection__to_node`](#connection__to_node)

### `diff_coeff`

**Relationship class**: [`node__node`](#node__node)

**Default value**: `0.0`

Commodity diffusion coefficient between two `nodes`. Effectively, denotes the *diffusion power per unit of state* from the first `node` to the second.

### `stochastic_scenario_end`

**Relationship class**: [`stochastic_structure__stochastic_scenario`](#stochastic_structure__stochastic_scenario)

A `Duration` for when a `stochastic_scenario` ends and its `child_stochastic_scenarios` start. Values are interpreted relative to the start of the current solve, and if no value is given, the `stochastic_scenario` is assumed to continue indefinitely.

### `weight_relative_to_parents`

**Relationship class**: [`stochastic_structure__stochastic_scenario`](#stochastic_structure__stochastic_scenario)

**Default value**: `1.0`

The weight of the `stochastic_scenario` in the objective function relative to its parents.

### `fix_nonspin_ramp_up_unit_flow`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Fix the `nonspin_ramp_up_unit_flow` variable.

### `fix_nonspin_units_starting_up`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Fix the `nonspin_units_starting_up` variable.

### `fix_ramp_up_unit_flow`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Fix the `ramp_up_unit_flow` variable.

### `fix_start_up_unit_flow`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Fix the `start_up_unit_flow` variable.

### `fix_unit_flow`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Fix the `unit_flow` variable.

### `fix_unit_flow_op`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Fix the `unit_flow_op` variable.

### `fuel_cost`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Variable fuel costs than can be attributed to a `unit_flow`. E.g. EUR/MWh

### `graph_view_position`

**Relationship class**: [`unit__from_node`](#unit__from_node)

### `max_res_startup_ramp`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Maximum non-spinning reserve ramp-up for startups?

### `max_startup_ramp`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Maximum ramp-up during startups?

### `min_res_startup_ramp`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Minimum non-spinning reserve ramp-up for startups?

### `min_startup_ramp`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Minimum ramp-up during startups?

### `minimum_operating_point`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Minimum level for the `unit_flow` relative to the `units_on` online capacity.

### `operating_cost`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Operating costs of a `unit_flow` variable. E.g. EUR/MWh.

### `operating_points`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Operating points for piecewise-linear `unit` efficiency approximations?

### `ramp_up_limit`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Limit the maximum ramp-up rate of a `unit_flow` variable.

### `unit_capacity`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Maximum `unit_flow` capacity of a single 'sub_unit' of the `unit`.

### `unit_conv_cap_to_flow`

**Relationship class**: [`unit__from_node`](#unit__from_node)

**Default value**: `1.0`

Optional coefficient for `unit_capacity` unit conversions in the case the `unit_capacity` value is incompatible with the desired `unit_flow` units.

### `vom_cost`

**Relationship class**: [`unit__from_node`](#unit__from_node)

Variable operating costs of a `unit_flow` variable. E.g. EUR/MWh.

### `res_start_up_cost`

**Relationship class**: [`unit__from_node`](#unit__from_node)

TODO

### `graph_view_position`

**Relationship class**: [`unit__from_node__unit_constraint`](#unit__from_node__unit_constraint)

### `unit_flow_coefficient`

**Relationship class**: [`unit__from_node__unit_constraint`](#unit__from_node__unit_constraint)

**Default value**: `0.0`

Coefficient of a `unit_flow` variable for a custom `unit_constraint`?

### `fix_ratio_in_in_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Fix the ratio between two `unit_flows` coming into the `unit` from the two `nodes`.

### `fix_ratio_in_out_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Fix the ratio between an incoming `unit_flow` from the first `node` and an outgoing `unit_flow` to the second `node`.

### `fix_ratio_out_in_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Fix the ratio between an outgoing `unit_flow` to the first `node` and an incoming `unit_flow` from the second `node`.

### `fix_ratio_out_out_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Fix the ratio between two `unit_flows` going from the `unit` into the two `nodes`.

### `fix_units_on_coefficient_in_in`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `fix_ratio_in_in_unit_flow` constraint.

### `fix_units_on_coefficient_in_out`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `fix_ratio_in_out_unit_flow` constraint.

### `fix_units_on_coefficient_out_in`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `fix_ratio_out_in_unit_flow` constraint.

### `fix_units_on_coefficient_out_out`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `fix_ratio_out_out_unit_flow` constraint.

### `max_ratio_in_in_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Maximum ratio between two `unit_flows` coming into the `unit` from the two `nodes`.

### `max_ratio_in_out_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Maximum ratio between an incoming `unit_flow` from the first `node` and an outgoing `unit_flow` to the second `node`.

### `max_ratio_out_in_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Maximum ratio between an outgoing `unit_flow` to the first `node` and an incoming `unit_flow` from the second `node`.

### `max_ratio_out_out_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Maximum ratio between two `unit_flows` going from the `unit` into the two `nodes`.

### `max_units_on_coefficient_in_in`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `max_ratio_in_in_unit_flow` constraint.

### `max_units_on_coefficient_in_out`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `max_ratio_in_out_unit_flow` constraint.

### `max_units_on_coefficient_out_in`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `max_ratio_out_in_unit_flow` constraint.

### `max_units_on_coefficient_out_out`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `max_ratio_out_out_unit_flow` constraint.

### `min_ratio_in_in_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Minimum ratio between two `unit_flows` coming into the `unit` from the two `nodes`.

### `min_ratio_in_out_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Minimum ratio between an incoming `unit_flow` from the first `node` and an outgoing `unit_flow` to the second `node`.

### `min_ratio_out_in_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Minimum ratio between an outgoing `unit_flow` to the first `node` and an incoming `unit_flow` from the second `node`.

### `min_ratio_out_out_unit_flow`

**Relationship class**: [`unit__node__node`](#unit__node__node)

Minimum ratio between two `unit_flows` going from the `unit` into the two `nodes`.

### `min_units_on_coefficient_in_in`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `min_ratio_in_in_unit_flow` constraint.

### `min_units_on_coefficient_in_out`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `min_ratio_in_out_unit_flow` constraint.

### `min_units_on_coefficient_out_in`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `min_ratio_out_in_unit_flow` constraint.

### `min_units_on_coefficient_out_out`

**Relationship class**: [`unit__node__node`](#unit__node__node)

**Default value**: `0.0`

Optional coefficient for the `units_on` variable impacting the `min_ratio_out_out_unit_flow` constraint.

### `fix_nonspin_ramp_up_unit_flow`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Fix the `nonspin_ramp_up_unit_flow` variable.

### `fix_nonspin_units_starting_up`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Fix the `nonspin_units_starting_up` variable.

### `fix_ramp_up_unit_flow`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Fix the `ramp_up_unit_flow` variable.

### `fix_start_up_unit_flow`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Fix the `start_up_unit_flow` variable.

### `fix_unit_flow`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Fix the `unit_flow` variable.

### `fix_unit_flow_op`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Fix the `unit_flow_op` variable.

### `fuel_cost`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Variable fuel costs than can be attributed to a `unit_flow`. E.g. EUR/MWh

### `graph_view_position`

**Relationship class**: [`unit__to_node`](#unit__to_node)

### `max_res_startup_ramp`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Maximum non-spinning reserve ramp-up for startups?

### `max_startup_ramp`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Maximum ramp-up during startups?

### `min_res_startup_ramp`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Minimum non-spinning reserve ramp-up for startups?

### `min_startup_ramp`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Minimum ramp-up during startups?

### `minimum_operating_point`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Minimum level for the `unit_flow` relative to the `units_on` online capacity.

### `operating_cost`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Operating costs of a `unit_flow` variable. E.g. EUR/MWh.

### `operating_points`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Operating points for piecewise-linear `unit` efficiency approximations?

### `ramp_up_limit`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Limit the maximum ramp-up rate of a `unit_flow` variable.

### `unit_capacity`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Maximum `unit_flow` capacity of a single 'sub_unit' of the `unit`.

### `unit_conv_cap_to_flow`

**Relationship class**: [`unit__to_node`](#unit__to_node)

**Default value**: `1.0`

Optional coefficient for `unit_capacity` unit conversions in the case the `unit_capacity` value is incompatible with the desired `unit_flow` units.

### `vom_cost`

**Relationship class**: [`unit__to_node`](#unit__to_node)

Variable operating costs of a `unit_flow` variable. E.g. EUR/MWh.

### `res_start_up_cost`

**Relationship class**: [`unit__to_node`](#unit__to_node)

TODO

### `graph_view_position`

**Relationship class**: [`unit__to_node__unit_constraint`](#unit__to_node__unit_constraint)

### `unit_flow_coefficient`

**Relationship class**: [`unit__to_node__unit_constraint`](#unit__to_node__unit_constraint)

**Default value**: `0.0`

Coefficient of a `unit_flow` variable for a custom `unit_constraint`?

### `units_on_coefficient`

**Relationship class**: [`unit__unit_constraint`](#unit__unit_constraint)

**Default value**: `0.0`

Coefficient of a `units_on` variable for a custom `unit_constraint`?

### `max_cum_in_unit_flow_bound`

**Relationship class**: [`unit__commodity`](#unit__commodity)

Set a maximum cumulative upped bound for a `unit_flow`?

## parameter_value_lists

### `balance_type_list`

**Value**: `balance_type_node`

**Value**: `balance_type_group`

**Value**: `balance_type_none`

### `boolean_value_list`

**Value**: `true`

**Value**: `false`

### `commodity_physics_list`

**Value**: `commodity_physics_ptdf`

**Value**: `commodity_physics_lodf`

**Value**: `commodity_physics_none`

### `constraint_sense_list`

**Value**: `==`

**Value**: `>=`

**Value**: `<=`

### `duration_unit_list`

**Value**: `minute`

**Value**: `hour`

### `node_opf_type_list`

**Value**: `node_opf_type_normal`

**Value**: `node_opf_type_reference`

### `unit_investment_variable_type_list`

**Value**: `unit_investment_variable_type_integer`

**Value**: `unit_investment_variable_type_continuous`

### `unit_online_variable_type_list`

**Value**: `unit_online_variable_type_binary`

**Value**: `unit_online_variable_type_integer`

**Value**: `unit_online_variable_type_linear`

### `connection_type_list`

**Value**: `connection_type_normal`

**Value**: `connection_type_lossless_bidirectional`

### `write_mps_file_list`

**Value**: `write_mps_on_no_solve`

**Value**: `write_mps_always`

**Value**: `write_mps_never`

