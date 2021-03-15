# Parameters

## `balance_type`

A selector for how the `:nodal_balance` constraint should be handled.

Related [Object Classes](@ref): [node](@ref)

Default value: balance_type_node

Uses [Parameter Value Lists](@ref): [balance\_type\_list](@ref)

TODO

## `block_end`

The end time for the `temporal_block`. Can be given either as a `DateTime` for a static end point, or as a `Duration` for an end point relative to the start of the current optimization.

Related [Object Classes](@ref): [temporal\_block](@ref)

Default value: nothing

TODO

## `block_start`

The start time for the `temporal_block`. Can be given either as a `DateTime` for a static start point, or as a `Duration` for an start point relative to the start of the current optimization.

Related [Object Classes](@ref): [temporal\_block](@ref)

Default value: nothing

TODO

## `candidate_connections`

The number of connections that may be invested in

Related [Object Classes](@ref): [connection](@ref)

Default value: nothing

TODO

## `candidate_storages`

Determines the maximum number of new storages which may be invested in

Related [Object Classes](@ref): [node](@ref)

Default value: nothing

TODO

## `candidate_units`

Number of units which may be additionally constructed

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `commodity_lodf_tolerance`

LODF tolerance?

Related [Object Classes](@ref): [commodity](@ref)

Default value: 0.1

TODO

## `commodity_physics`

Defines if the `commodity` follows lodf or ptdf physics.

Related [Object Classes](@ref): [commodity](@ref)

Default value: commodity_physics_none

Uses [Parameter Value Lists](@ref): [commodity\_physics\_list](@ref)

TODO

## `commodity_ptdf_threshold`

PTDF threshold?

Related [Object Classes](@ref): [commodity](@ref)

Default value: 0.0001

TODO

## `connection_availability_factor`

Availability of the `connection`, acting as a multiplier on its `connection_capacity`. Typically between 0-1.

Related [Object Classes](@ref): [connection](@ref)

Default value: 1.0

TODO

## `connection_capacity`

Limits the `connection_flow` variable from the `from_node`. `from_node` can be a group of `nodes`, in which case the sum of the `connection_flow` is constrained. Limits the `connection_flow` variable to the `to_node`. `to_node` can be a group of `nodes`, in which case the sum of the `connection_flow` is constrained.

Related [Relationship Classes](@ref): [connection\_\_from\_node](@ref) and [connection\_\_to\_node](@ref)

Default value: nothing

TODO

## `connection_contingency`

A boolean flag for defining a contingency `connection`.

Related [Object Classes](@ref): [connection](@ref)

Default value: nothing

Uses [Parameter Value Lists](@ref): [boolean\_value\_list](@ref)

TODO

## `connection_conv_cap_to_flow`

Optional coefficient for `connection_capacity` unit conversions in the case the `connection_capacity` value is incompatible with the desired `connection_flow` units.

Related [Relationship Classes](@ref): [connection\_\_from\_node](@ref) and [connection\_\_to\_node](@ref)

Default value: 1.0

TODO

## `connection_emergency_capacity`

Emergy capacity of a `connection`? Post contingency flow capacity of a `connection`. Sometimes referred to as emergency rating

Related [Relationship Classes](@ref): [connection\_\_from\_node](@ref) and [connection\_\_to\_node](@ref)

Default value: nothing

TODO

## `connection_flow_coefficient`

defines the unit constraint coefficient on the connection flow variable in the from direction defines the unit constraint coefficient on the connection flow variable in the to direction

Related [Relationship Classes](@ref): [connection\_\_from\_node\_\_unit\_constraint](@ref) and [connection\_\_to\_node\_\_unit\_constraint](@ref)

Default value: 0.0

TODO

## `connection_flow_cost`

Variable costs of a flow through a `connection`. E.g. EUR/MWh of energy throughput.

Related [Object Classes](@ref): [connection](@ref)

Default value: nothing

TODO

## `connection_flow_delay`

Delays the `connection_flows` associated with the latter `node` in respect to the `connection_flows` associated with the first `node`.

Related [Relationship Classes](@ref): [connection\_\_node\_\_node](@ref)

Default value: Dict{String,Any}("data" => "0h","type" => "duration")

TODO

## `connection_investment_cost`

The per unit investment cost for the connection over the `connection_investment_lifetime`

Related [Object Classes](@ref): [connection](@ref)

Default value: nothing

TODO

## `connection_investment_lifetime`

Determines the minimum investment lifetime of a connection. Once invested, it remains in service for this long

Related [Object Classes](@ref): [connection](@ref)

Default value: nothing

TODO

## `connection_investment_variable_type`

Determines whether the investment variable is integer (variable_type_integer) or continuous (variable_type_continuous)

Related [Object Classes](@ref): [connection](@ref)

Default value: variable_type_integer

Uses [Parameter Value Lists](@ref): [variable\_type\_list](@ref)

TODO

## `connection_monitored`

A boolean flag for defining a contingency `connection`.

Related [Object Classes](@ref): [connection](@ref)

Default value: false

Uses [Parameter Value Lists](@ref): [boolean\_value\_list](@ref)

TODO

## `connection_reactance`

Reactance of a `connection`.

Related [Object Classes](@ref): [connection](@ref)

Default value: nothing

TODO

## `connection_resistance`

Resistance of a `connection`.

Related [Object Classes](@ref): [connection](@ref)

Default value: nothing

TODO

## `connection_type`

A selector between a normal and a lossless bidirectional `connection`.

Related [Object Classes](@ref): [connection](@ref)

Default value: connection_type_normal

Uses [Parameter Value Lists](@ref): [connection\_type\_list](@ref)

TODO

## `constraint_sense`

A selector for the sense of the `unit_constraint`.

Related [Object Classes](@ref): [unit\_constraint](@ref)

Default value: ==

Uses [Parameter Value Lists](@ref): [constraint\_sense\_list](@ref)

TODO

## `curtailment_cost`

Costs for curtailing generation. Essentially, accrues costs whenever `unit_flow` not operating at its maximum available capacity. E.g. EUR/MWh

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `demand`

Demand for the `commodity` of a `node`. Energy gains can be represented using negative `demand`.

Related [Object Classes](@ref): [node](@ref)

Default value: 0.0

TODO

## `demand_coefficient`

coefficient of the specified node's demand in the specified unit constraint

Related [Relationship Classes](@ref): [node\_\_unit\_constraint](@ref)

Default value: 0.0

TODO

## `diff_coeff`

Commodity diffusion coefficient between two `nodes`. Effectively, denotes the *diffusion power per unit of state* from the first `node` to the second.

Related [Relationship Classes](@ref): [node\_\_node](@ref)

Default value: 0.0

TODO

## `downward_reserve`

Identifier for `node`s providing downward reserves

Related [Object Classes](@ref): [node](@ref)

Default value: false

TODO

## `duration_unit`

Defines the base temporal unit of the `model`. Currently supported values are either an `hour` or a `minute`.

Related [Object Classes](@ref): [model](@ref)

Default value: minute

Uses [Parameter Value Lists](@ref): [duration\_unit\_list](@ref)

TODO

## `fix_connection_flow`

Fix the value of the `connection_flow` variable.

Related [Relationship Classes](@ref): [connection\_\_from\_node](@ref) and [connection\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_connection_intact_flow`

Fix the value of the `connection_intact_flow` variable.

Related [Relationship Classes](@ref): [connection\_\_from\_node](@ref) and [connection\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_connections_invested`

Setting a value fixes the connections_invested variable accordingly

Related [Object Classes](@ref): [connection](@ref)

Default value: nothing

TODO

## `fix_connections_invested_available`

Setting a value fixes the connections_invested_available variable accordingly

Related [Object Classes](@ref): [connection](@ref)

Default value: nothing

TODO

## `fix_node_state`

Fixes the corresponding `node_state` variable to the provided value. Can be used for e.g. fixing boundary conditions.

Related [Object Classes](@ref): [node](@ref)

Default value: nothing

TODO

## `fix_nonspin_ramp_down_unit_flow`

Fix the `nonspin_ramp_down_unit_flow` variable.

Related [Relationship Classes](@ref): [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_nonspin_ramp_up_unit_flow`

Fix the `nonspin_ramp_up_unit_flow` variable.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_nonspin_units_shut_down`

Fix the `nonspin_units_shut_down` variable.

Related [Relationship Classes](@ref): [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_nonspin_units_started_up`

Fix the `nonspin_units_started_up` variable.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_nonspin_units_starting_up`

Fix the `nonspin_units_starting_up` variable.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_ramp_down_unit_flow`

Fix the `ramp_down_unit_flow` variable.

Related [Relationship Classes](@ref): [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_ramp_up_unit_flow`

Fix the `ramp_up_unit_flow` variable.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_ratio_in_in_unit_flow`

Fix the ratio between two `unit_flows` coming into the `unit` from the two `nodes`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `fix_ratio_in_out_unit_flow`

Fix the ratio between an incoming `unit_flow` from the first `node` and an outgoing `unit_flow` to the second `node`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `fix_ratio_out_in_connection_flow`

Fix the ratio between the `connection_flow` from the first `node` and the `connection_flow` to the second `node`.

Related [Relationship Classes](@ref): [connection\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `fix_ratio_out_in_unit_flow`

Fix the ratio between an outgoing `unit_flow` to the first `node` and an incoming `unit_flow` from the second `node`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `fix_ratio_out_out_unit_flow`

Fix the ratio between two `unit_flows` going from the `unit` into the two `nodes`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `fix_shut_down_unit_flow`

Fix the `shut_down_unit_flow` variable.

Related [Relationship Classes](@ref): [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_start_up_unit_flow`

Fix the `start_up_unit_flow` variable.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_storages_invested`

Used to fix the value of the storages_invested variable

Related [Object Classes](@ref): [node](@ref)

Default value: nothing

TODO

## `fix_storages_invested_available`

Used to fix the value of the storages_invested_available variable

Related [Object Classes](@ref): [node](@ref)

Default value: nothing

TODO

## `fix_unit_flow`

Fix the `unit_flow` variable.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_unit_flow_op`

Fix the `unit_flow_op` variable.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `fix_units_invested`

Fix the value of the `units_invested` variable.

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `fix_units_invested_available`

Fix the value of the `units_invested_available` variable

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `fix_units_on`

Fix the value of the `units_on` variable.

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `fix_units_on_coefficient_in_in`

Optional coefficient for the `units_on` variable impacting the `fix_ratio_in_in_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `fix_units_on_coefficient_in_out`

Optional coefficient for the `units_on` variable impacting the `fix_ratio_in_out_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `fix_units_on_coefficient_out_in`

Optional coefficient for the `units_on` variable impacting the `fix_ratio_out_in_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `fix_units_on_coefficient_out_out`

Optional coefficient for the `units_on` variable impacting the `fix_ratio_out_out_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `fom_cost`

Fixed operation and maintenance costs of a `unit`. Essentially, a cost coefficient on the `number_of_units` and `unit_capacity` parameters. E.g. EUR/MWh

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `frac_state_loss`

Self-discharge coefficient for `node_state` variables. Effectively, represents the *loss power per unit of state*.

Related [Object Classes](@ref): [node](@ref)

Default value: 0.0

TODO

## `fractional_demand`

Fractional `demand` for `node` groups?

Related [Object Classes](@ref): [node](@ref)

Default value: 0.0

TODO

## `fuel_cost`

Variable fuel costs than can be attributed to a `unit_flow`. E.g. EUR/MWh

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `graph_view_position`

nothing

Related [Object Classes](@ref): [connection](@ref), [node](@ref) and [unit](@ref)

Related [Relationship Classes](@ref): [connection\_\_from\_node](@ref), [connection\_\_to\_node](@ref), [unit\_\_from\_node](@ref), [unit\_\_from\_node\_\_unit\_constraint](@ref), [unit\_\_to\_node](@ref) and [unit\_\_to\_node\_\_unit\_constraint](@ref)

Default value: nothing

TODO

## `has_state`

A boolean flag for whether a `node` has a `node_state` variable.

Related [Object Classes](@ref): [node](@ref)

Default value: false

Uses [Parameter Value Lists](@ref): [boolean\_value\_list](@ref)

TODO

## `is_active`

If false, the object is excluded from the model if the tool filter object activity control is specified

Related [Object Classes](@ref): [commodity](@ref), [connection](@ref), [model](@ref), [node](@ref), [output](@ref), [report](@ref), [stochastic\_scenario](@ref), [stochastic\_structure](@ref), [temporal\_block](@ref), [unit](@ref) and [unit\_constraint](@ref)

Default value: true

Uses [Parameter Value Lists](@ref): [boolean\_value\_list](@ref)

TODO

## `is_reserve_node`

A boolean flag for a `reserve_node`?

Related [Object Classes](@ref): [node](@ref)

Default value: false

Uses [Parameter Value Lists](@ref): [boolean\_value\_list](@ref)

TODO

## `max_cum_in_unit_flow_bound`

Set a maximum cumulative upped bound for a `unit_flow`?

Related [Relationship Classes](@ref): [unit\_\_commodity](@ref)

Default value: nothing

TODO

## `max_gap`

Specifies the maximum optimality gap for the model. Interpretation depends on model_type parameter

Related [Object Classes](@ref): [model](@ref)

Default value: 0.05

TODO

## `max_iterations`

Specifies the maximum number of iterations for the model. Interpretation depends on model_type parameter

Related [Object Classes](@ref): [model](@ref)

Default value: 10.0

TODO

## `max_ratio_in_in_unit_flow`

Maximum ratio between two `unit_flows` coming into the `unit` from the two `nodes`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `max_ratio_in_out_unit_flow`

Maximum ratio between an incoming `unit_flow` from the first `node` and an outgoing `unit_flow` to the second `node`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `max_ratio_out_in_connection_flow`

Maximum ratio between the `connection_flow` from the first `node` and the `connection_flow` to the second `node`.

Related [Relationship Classes](@ref): [connection\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `max_ratio_out_in_unit_flow`

Maximum ratio between an outgoing `unit_flow` to the first `node` and an incoming `unit_flow` from the second `node`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `max_ratio_out_out_unit_flow`

Maximum ratio between two `unit_flows` going from the `unit` into the two `nodes`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `max_res_shutdown_ramp`

Max. downward reserve ramp for online units scheduled to shut down for reserve provision Maximum non-spinning reserve ramp-down for online units providing reserves during shut-downs

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `max_res_startup_ramp`

Maximum non-spinning reserve ramp-up for offline units scheduled for reserve provision Maximum non-spinning reserve ramp-up for startups?

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `max_shutdown_ramp`

Max. downward ramp for units shutting down Maximum ramp-down during shutdowns

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `max_startup_ramp`

Maximum ramp-up during startups Maximum ramp-up during startups?

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `max_units_on_coefficient_in_in`

Optional coefficient for the `units_on` variable impacting the `max_ratio_in_in_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `max_units_on_coefficient_in_out`

Optional coefficient for the `units_on` variable impacting the `max_ratio_in_out_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `max_units_on_coefficient_out_in`

Optional coefficient for the `units_on` variable impacting the `max_ratio_out_in_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `max_units_on_coefficient_out_out`

Optional coefficient for the `units_on` variable impacting the `max_ratio_out_out_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `min_down_time`

Minimum downtime of a `unit` after it shuts down.

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `min_ratio_in_in_unit_flow`

Minimum ratio between two `unit_flows` coming into the `unit` from the two `nodes`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `min_ratio_in_out_unit_flow`

Minimum ratio between an incoming `unit_flow` from the first `node` and an outgoing `unit_flow` to the second `node`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `min_ratio_out_in_connection_flow`

Minimum ratio between the `connection_flow` from the first `node` and the `connection_flow` to the second `node`.

Related [Relationship Classes](@ref): [connection\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `min_ratio_out_in_unit_flow`

Minimum ratio between an outgoing `unit_flow` to the first `node` and an incoming `unit_flow` from the second `node`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `min_ratio_out_out_unit_flow`

Minimum ratio between two `unit_flows` going from the `unit` into the two `nodes`.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `min_res_shutdown_ramp`

Minimum non-spinning reserve ramp-down for online units providing reserves during shut-downs

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `min_res_startup_ramp`

Minimum non-spinning reserve ramp-up for offline units scheduled for reserve provision Minimum non-spinning reserve ramp-up for startups?

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `min_shutdown_ramp`

Minimum ramp-up during startups

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `min_startup_ramp`

Minimum ramp-up during startups Minimum ramp-up during startups?

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `min_units_on_coefficient_in_in`

Optional coefficient for the `units_on` variable impacting the `min_ratio_in_in_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `min_units_on_coefficient_in_out`

Optional coefficient for the `units_on` variable impacting the `min_ratio_in_out_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `min_units_on_coefficient_out_in`

Optional coefficient for the `units_on` variable impacting the `min_ratio_out_in_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `min_units_on_coefficient_out_out`

Optional coefficient for the `units_on` variable impacting the `min_ratio_out_out_unit_flow` constraint.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `min_up_time`

Minimum uptime of a `unit` after it starts up.

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `minimum_operating_point`

Minimum level for the `unit_flow` relative to the `units_on` online capacity.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `minimum_reserve_activation_time`

Duration a certain reserve product needs to be online/available

Related [Object Classes](@ref): [node](@ref)

Default value: nothing

TODO

## `model_end`

Defines the last timestamp to be modelled. Rolling optimization terminates after passing this point.

Related [Object Classes](@ref): [model](@ref)

Default value: Dict{String,Any}("data" => "2000-01-02T00:00:00","type" => "date_time")

TODO

## `model_start`

Defines the first timestamp to be modelled. Relative `temporal_blocks` refer to this value for their start and end.

Related [Object Classes](@ref): [model](@ref)

Default value: Dict{String,Any}("data" => "2000-01-01T00:00:00","type" => "date_time")

TODO

## `model_type`

Used to identify model objects as relating to the master problem or operational sub problems (default)

Related [Object Classes](@ref): [model](@ref)

Default value: spineopt_operations

Uses [Parameter Value Lists](@ref): [model\_type\_list](@ref)

TODO

## `nodal_balance_sense`

A selector for `nodal_balance` constraint sense.

Related [Object Classes](@ref): [node](@ref)

Default value: ==

Uses [Parameter Value Lists](@ref): [constraint\_sense\_list](@ref)

TODO

## `node_opf_type`

A selector for `node_opf_type`?

Related [Object Classes](@ref): [node](@ref)

Default value: node_opf_type_normal

Uses [Parameter Value Lists](@ref): [node\_opf\_type\_list](@ref)

TODO

## `node_slack_penalty`

A penalty cost for `node_slack_pos` and `node_slack_neg` variables. The slack variables won't be included in the model unless there's a cost defined for them.

Related [Object Classes](@ref): [node](@ref)

Default value: nothing

TODO

## `node_state_cap`

The maximum permitted value for a `node_state` variable.

Related [Object Classes](@ref): [node](@ref)

Default value: nothing

TODO

## `node_state_coefficient`

coefficient of the specified node's state variable in the specified unit constraint

Related [Relationship Classes](@ref): [node\_\_unit\_constraint](@ref)

Default value: 0.0

TODO

## `node_state_min`

The minimum permitted value for a `node_state` variable.

Related [Object Classes](@ref): [node](@ref)

Default value: 0.0

TODO

## `number_of_units`

Denotes the number of 'sub units' aggregated to form the modelled `unit`.

Related [Object Classes](@ref): [unit](@ref)

Default value: 1.0

TODO

## `online_variable_type`

A selector for how the `units_on` variable is represented within the model.

Related [Object Classes](@ref): [unit](@ref)

Default value: unit_online_variable_type_linear

Uses [Parameter Value Lists](@ref): [unit\_online\_variable\_type\_list](@ref)

TODO

## `operating_cost`

Operating costs of a `unit_flow` variable. E.g. EUR/MWh.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `operating_points`

Operating points for piecewise-linear `unit` efficiency approximations?

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `output_db_url`

Database url for SpineOpt output.

Related [Object Classes](@ref): [report](@ref)

Default value: nothing

TODO

## `ramp_down_cost`

Costs of ramping down

Related [Relationship Classes](@ref): [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `ramp_down_costs`

Costs for ramping down

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref)

Default value: nothing

TODO

## `ramp_down_limit`

Limit the maximum ramp-down rate of an online unit. Max. ramp down limit of online units

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `ramp_up_cost`

Costs of ramping up

Related [Relationship Classes](@ref): [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `ramp_up_costs`

Costs for ramping up

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref)

Default value: nothing

TODO

## `ramp_up_limit`

Limit the maximum ramp-up rate of a `unit_flow` variable. Limit the maximum ramp-up rate of an online unit.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `res_start_up_cost`

TODO

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `reserve_procurement_cost`

Procurement cost for reserves?

Related [Object Classes](@ref): [node](@ref)

Default value: nothing

TODO

## `resolution`

Temporal resolution of the `temporal_block`. Essentially, divides the period between `block_start` and `block_end` into `TimeSlices` with the input `resolution`.

Related [Object Classes](@ref): [temporal\_block](@ref)

Default value: Dict{String,Any}("data" => "1h","type" => "duration")

TODO

## `right_hand_side`

The right-hand side of the `unit_constraint`. Can be used e.g. for complicated time-dependent efficiency approximations.

Related [Object Classes](@ref): [unit\_constraint](@ref)

Default value: 0.0

TODO

## `roll_forward`

Defines how much the model moves ahead in time between solves in a rolling optimization. Without this parameter, everything is solved in as a single optimization.

Related [Object Classes](@ref): [model](@ref)

Default value: nothing

TODO

## `shut_down_cost`

Costs of shutting down a 'sub unit', e.g. EUR/shutdown.

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `start_up_cost`

Costs of starting up a 'sub unit', e.g. EUR/startup.

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `state_coeff`

Represents the `commodity` content of a `node_state` variable in respect to the `unit_flow` and `connection_flow` variables. Essentially, acts as a coefficient on the `node_state` variable in the `:node_injection` constraint.

Related [Object Classes](@ref): [node](@ref)

Default value: 0.0

TODO

## `stochastic_scenario_end`

A `Duration` for when a `stochastic_scenario` ends and its `child_stochastic_scenarios` start. Values are interpreted relative to the start of the current solve, and if no value is given, the `stochastic_scenario` is assumed to continue indefinitely.

Related [Relationship Classes](@ref): [stochastic\_structure\_\_stochastic\_scenario](@ref)

Default value: nothing

The [stochastic\_scenario\_end](@ref) is a `Duration`-type parameter,
defining when a [stochastic\_scenario](@ref) ends relative to the start of the current optimization.
As it is a parameter for the [stochastic\_structure\_\_stochastic\_scenario](@ref) relationship, different
[stochastic\_structure](@ref)s can have different values for the same [stochastic\_scenario](@ref), making it
possible to define slightly different [stochastic\_structure](@ref)s using the same [stochastic\_scenario](@ref)s.
See the [Stochastic Framework](@ref) section for more information about how different [stochastic\_structure](@ref)s
interact in *SpineOpt.jl*.

When a [stochastic\_scenario](@ref) ends at the point in time defined by the [stochastic\_scenario\_end](@ref)
parameter, it spawns its children according to the [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref)
relationship.
Note that the children will be inherently assumed to belong to the same [stochastic\_structure](@ref) their parent
belonged to, even without explicit [stochastic\_structure\_\_stochastic\_scenario](@ref) relationships!
Thus, you might need to define the [weight\_relative\_to\_parents](@ref) parameter for the children.

If no [stochastic\_scenario\_end](@ref) is defined, the [stochastic\_scenario](@ref) is assumed to go on indefinitely.

## `storage_investment_cost`

Determines the investment cost per unit state_cap over the investment life of a storage

Related [Object Classes](@ref): [node](@ref)

Default value: nothing

TODO

## `storage_investment_lifetime`

nothing

Related [Object Classes](@ref): [node](@ref)

Default value: nothing

TODO

## `storage_investment_variable_type`

Determines whether the storage investment variable is continuous (usually representing capacity) or integer (representing discrete units invested)

Related [Object Classes](@ref): [node](@ref)

Default value: variable_type_integer

Uses [Parameter Value Lists](@ref): [variable\_type\_list](@ref)

TODO

## `tax_in_unit_flow`

Tax costs for incoming `unit_flows` on this `node`. E.g. EUR/MWh.

Related [Object Classes](@ref): [node](@ref)

Default value: 0.0

TODO

## `tax_net_unit_flow`

Tax costs for net incoming and outgoing `unit_flows` on this `node`. Incoming flows accrue positive net taxes, and outgoing flows accrue negative net taxes.

Related [Object Classes](@ref): [node](@ref)

Default value: 0.0

TODO

## `tax_out_unit_flow`

Tax costs for outgoing `unit_flows` from this `node`. E.g. EUR/MWh.

Related [Object Classes](@ref): [node](@ref)

Default value: 0.0

TODO

## `unit_availability_factor`

Availability of the `unit`, acting as a multiplier on its `unit_capacity`. Typically between 0-1.

Related [Object Classes](@ref): [unit](@ref)

Default value: 1.0

TODO

## `unit_capacity`

Maximum `unit_flow` capacity of a single 'sub_unit' of the `unit`.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `unit_conv_cap_to_flow`

Optional coefficient for `unit_capacity` unit conversions in the case the `unit_capacity` value is incompatible with the desired `unit_flow` units.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: 1.0

TODO

## `unit_flow_coefficient`

Coefficient of a `unit_flow` variable for a custom `unit_constraint`. Coefficient of a `unit_flow` variable for a custom `unit_constraint`?

Related [Relationship Classes](@ref): [unit\_\_from\_node\_\_unit\_constraint](@ref) and [unit\_\_to\_node\_\_unit\_constraint](@ref)

Default value: 0.0

TODO

## `unit_idle_heat_rate`

Flow from node1 per unit time and per `units_on` that results in no additional flow to node2

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `unit_incremental_heat_rate`

Standard piecewise incremental heat rate where node1 is assumed to be the fuel and node2 is assumed to be electriciy. Assumed monotonically increasing. Array type or single coefficient where the number of coefficients must match the dimensions of `unit_operating_points`

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: nothing

TODO

## `unit_investment_cost`

Investment cost per 'sub unit' built.

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `unit_investment_lifetime`

Minimum lifetime for investment decisions.

Related [Object Classes](@ref): [unit](@ref)

Default value: nothing

TODO

## `unit_investment_variable_type`

Determines whether investment variable is integer or continuous.

Related [Object Classes](@ref): [unit](@ref)

Default value: unit_investment_variable_type_continuous

Uses [Parameter Value Lists](@ref): [unit\_investment\_variable\_type\_list](@ref)

TODO

## `unit_start_flow`

Flow from node1 that is incurred when a unit is started up.

Related [Relationship Classes](@ref): [unit\_\_node\_\_node](@ref)

Default value: 0.0

TODO

## `units_on_coefficient`

Coefficient of a `units_on` variable for a custom `unit_constraint`.

Related [Relationship Classes](@ref): [unit\_\_unit\_constraint](@ref)

Default value: 0.0

TODO

## `units_started_up_coefficient`

Coefficient of a `units_started_up` variable for a custom `unit_constraint`.

Related [Relationship Classes](@ref): [unit\_\_unit\_constraint](@ref)

Default value: 0.0

TODO

## `upward_reserve`

Identifier for `node`s providing upward reserves

Related [Object Classes](@ref): [node](@ref)

Default value: false

TODO

## `vom_cost`

Variable operating costs of a `unit_flow` variable. E.g. EUR/MWh.

Related [Relationship Classes](@ref): [unit\_\_from\_node](@ref) and [unit\_\_to\_node](@ref)

Default value: nothing

TODO

## `weight_relative_to_parents`

The weight of the `stochastic_scenario` in the objective function relative to its parents.

Related [Relationship Classes](@ref): [stochastic\_structure\_\_stochastic\_scenario](@ref)

Default value: 1.0

The [weight\_relative\_to\_parents](@ref) parameter defines how much weight the [stochastic\_scenario](@ref) gets
in the [Objective function](@ref).
As a [stochastic\_structure\_\_stochastic\_scenario](@ref) relationship parameter, different 
[stochastic\_structure](@ref)s can use different weights for the same [stochastic\_scenario](@ref).
Note that every [stochastic\_scenario](@ref) that appears in the [model](@ref) must have a
[weight\_relative\_to\_parents](@ref) defined for it related to the used [stochastic\_structure](@ref)!
See the [Stochastic Framework](@ref) section for more information about how different [stochastic\_structure](@ref)s
interact in *SpineOpt.jl*.)

Since the [Stochastic Framework](@ref) in *SpineOpt.jl* supports *stochastic directed acyclic graphs* instead of simple
*stochastic trees*, it is possible to define [stochastic\_structure](@ref)s with converging
[stochastic\_scenario](@ref)s.
In these cases, the child [stochastic\_scenario](@ref)s inherint the weight of all of their parents, and the final
weight that will appear in the [Objective function](@ref) is calculated as shown below:

```
# For root `stochastic_scenarios` (meaning no parents)

weight(scenario) = weight_relative_to_parents(scenario)

# If not a root `stochastic_scenario`

weight(scenario) = sum([weight(parent) * weight_relative_to_parents(scenario)] for parent in parents)
```

The above calculation is performed starting from the roots, generation by generation,
until the leaves of the *stochastic DAG*.
Thus, the final weight of each [stochastic\_scenario](@ref) is dependent on the [weight\_relative\_to\_parents](@ref)
[Parameters](@ref) of all its ancestors.

## `write_lodf_file`

A boolean flag for whether the LODF values should be written to a results file.

Related [Object Classes](@ref): [model](@ref)

Default value: false

Uses [Parameter Value Lists](@ref): [boolean\_value\_list](@ref)

TODO

## `write_mps_file`

A selector for writing an .mps file of the model.

Related [Object Classes](@ref): [model](@ref)

Default value: nothing

Uses [Parameter Value Lists](@ref): [write\_mps\_file\_list](@ref)

TODO

## `write_ptdf_file`

A boolean flag for whether the LODF values should be written to a results file.

Related [Object Classes](@ref): [model](@ref)

Default value: false

Uses [Parameter Value Lists](@ref): [boolean\_value\_list](@ref)

TODO

