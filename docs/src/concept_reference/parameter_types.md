# parameter_types


## `balance_sense`

>**Related [Entity Classes](@ref):** [node](@ref)

[balance\_sense](@ref) determines whether or not a [node](@ref) is able to naturally
consume or produce energy. The default value, `==`, means that the [node](@ref) is unable to do any of that,
and thus it needs to be perfectly balanced. The vale `>=` means that the [node](@ref) is a *sink*,
that is, it can *consume* any amounts of energy. The value `<=` means that the [node](@ref) is a *source*,
that is, it can *produce* any amounts of energy.
## `balance_type`

>**Related [Entity Classes](@ref):** [node](@ref)

The [balance\_type](@ref) parameter determines whether or not a [node](@ref) needs to be balanced,
in the classical sense that the sum of flows entering the [node](@ref) is equal to the sum of flows
leaving it.

The values `node_balance` (the default) and `group_balance` mean that the [node](@ref) is always balanced according 
to the [nodal balance](@ref constraint_nodal_balance) and [node injection](@ref constraint_node_injection) constraints.

The only exceptions to enforcing the balance in the options above are if the [node](@ref) belongs in a group that has
itself [balance\_type](@ref) equal to `group_balance`.

The value `none` means that the [node](@ref) doesn't need to be balanced.
## `benders_iterations_reporting_active`

>**Related [Entity Classes](@ref):** [model](@ref)


## `binary_gas_flow_active`

>**Related [Entity Classes](@ref):** [connection](@ref)

This parameter is necessary for the use of pressure driven gas transfer, for which the direction of flow is not known a priori. The parameter [binary\_gas\_flow\_active](@ref) is a booelean method parameter, which - when set to [true](@ref boolean_value_list) - triggers the generation of the binary variables [binary\_gas\_connection\_flow](@ref), which (together with the [big\_m](@ref) parameter) forces the average flow through a pipeline to be unidirectional.

## `block_end`

>**Related [Entity Classes](@ref):** [temporal\_block](@ref)

Indicates the end of this temporal block. The default value is equal to a duration of 0. It is useful to distinguish here between two cases: a single solve, or a rolling window optimization.

**single solve**
When a Date time value is chosen, this is directly the end of the optimization for this temporal block. In a single solve optimization, a combination of [block\_start](@ref) and [block_end](@ref) can easily be used to run optimizations that cover only part of the model horizon. Multiple [temporal_block](@ref) objects can then be used to create optimizations for disconnected time periods, which is commonly used in the method of representative days. The default value coincides with the [model_end](@ref).

**rolling window optimization**
To create a temporal block that is rolling along with the optimization window, a rolling temporal block, a duration value should be chosen. The [block\_end](@ref) parameter will in this case determine the size of the optimization window, with respect to the start of each optimization window. If multiple temporal blocks with different [block\_end](@ref) parameters exist, the maximum value will determine the size of the optimization window. Note, this is different from the [roll_forward](@ref) parameter, which determines how much the window moves for after each optimization. For more info, see [One single `temporal_block`](@ref). The default value is equal to the [roll\_forward](@ref) parameter.

## `block_start`

>**Related [Entity Classes](@ref):** [temporal\_block](@ref)

Indicates the start of this temporal block. The main use of this parameter is to create an offset from the model start. The default value is equal to a duration of 0. It is useful to distinguish here between two cases: a single solve, or a rolling window optimization.

**single solve**
When a Date time value is chosen, this is directly the start of the optimization for this temporal block. When a duration is chosen, it is added to the [model\_start](@ref) to obtain the start of this [temporal\_block](@ref). In the case of a duration, the chosen value directly marks the offset of the optimization with respect to the [model\_start](@ref). The default value for this parameter is the [model\_start](@ref).

**rolling window optimization**
To create a temporal block that is rolling along with the optimization window, a rolling temporal block, a duration value should be chosen. The temporal [block\_start](@ref) will again mark the offset of the optimization start but now with respect to the start of each optimization window.

## `connection_flow_delay`

>**Related [Entity Classes](@ref):** [connection\_\_node\_\_node](@ref)

The [connection\_flow\_delay](@ref) parameter denotes the amount of time that it takes for the flow
to go through a [connection](@ref).
In other words, the flow that enters the [connection](@ref) is only seen at the other side after
[connection\_flow\_delay](@ref) units of time.

## `connection_flow_highest_resolution_active`

>**Related [Entity Classes](@ref):** [model](@ref)


## `connection_flow_non_anticipativity_time`

>**Related [Entity Classes](@ref):** [connection\_\_from\_node](@ref)


## `connection_intact_flow_non_anticipativity_time`

>**Related [Entity Classes](@ref):** [connection\_\_from\_node](@ref)


## `connection_investment_power_flow_impact_active`

>**Related [Entity Classes](@ref):** [model](@ref)


## `connection_type`

>**Related [Entity Classes](@ref):** [connection](@ref)

Used to control specific pre-processing actions on connections. Currently, the primary purpose of `connection_type` is to simplify the data that is required to define a simple bi-directional, lossless line. If `connection_type`=`:connection_type_lossless_bidirectional`, it is only necessary to specify the following minimum data:
 - relationship: [connection__from_node](@ref)
 - relationship: [connection__to_node](@ref)
 - parameter: [capacity_per_connection](@ref) (defined on [connection__from_node](@ref) and/or [connection__to_node](@ref))
If `connection_type`=`:connection_type_lossless_bidirectional` the following pre-processing actions are taken:
 - reciprocal [connection__from_node](@ref) and [connection__to_node](@ref) relationships are created if they don't exist
 - a new [connection\_\_node\_\_node](@ref) relationship is created if none exists already
 - [fix\_ratio\_out\_in\_connection\_flow](@ref) parameter is created with the value of 1 if no existing parameter found (therefore this value can be overridden)
 - The first [capacity_per_connection](@ref) parameter found is copied to [connection__from_node](@ref)s and [connection__to_node](@ref)s without a defined [capacity_per_connection](@ref).

## `constraint_sense`

>**Related [Entity Classes](@ref):** [user\_constraint](@ref)

The [constraint\_sense](@ref) parameter determines the *sense* of a custom user constraint.

See [User constraints](@ref) for details.

## `contingency_active`

>**Related [Entity Classes](@ref):** [connection](@ref)

Specifies that the connection in question is to be included as a contingency when security constrained unit commitment is enabled. When using security constrained unit commitment by setting [physics\_type](@ref) to [lodf\_physics](@ref grid_physics_list), an N-1 security constraint is created for each monitored line (`monitoring_active` = `true`) for each specified contingency (`contingency_active` = `true`).

See also [powerflow](@ref ptdf-based-powerflow)

## `cyclic_condition`

>**Related [Entity Classes](@ref):** [node\_\_temporal\_block](@ref)

The [cyclic\_condition](@ref) parameter is used to enforce that the storage level
at the end of the optimization window is higher or equal to the storage level
at the beginning optimization. If the [cyclic\_condition](@ref) parameter is set to [true](@ref boolean_value_list)
for a [node\_\_temporal\_block](@ref) relationship, and the [storage\_active](@ref) parameter of the corresponding [node](@ref) is set to [true](@ref boolean_value_list), the [constraint\_cyclic\_node\_state](@ref) will be triggered.

## `cyclic_condition_sense`

>**Related [Entity Classes](@ref):** [node\_\_temporal\_block](@ref)


## `decommissioning_time`

>**Related [Entity Classes](@ref):** [connection](@ref) and [unit](@ref)


## `discount_year`

>**Related [Entity Classes](@ref):** [model](@ref)


## `duration_unit`

>**Related [Entity Classes](@ref):** [model](@ref)

The [duration\_unit](@ref) parameter specifies the base unit of time in a [model](@ref).
Two values are currently supported, `hour` and the default `minute`.
E.g. if the [duration\_unit](@ref) is set to `hour`, a `Duration` of one `minute` gets converted into `1/60 hours`
for the calculations.
## `equal_investments_active`

>**Related [Entity Classes](@ref):** [investment\_group](@ref)


## `include_in_non_representative_periods`

>**Related [Entity Classes](@ref):** [user\_constraint](@ref)


## `investment_variable_type`

>**Related [Entity Classes](@ref):** [connection](@ref) and [unit](@ref)

Defines the type of the variables used for investment decisions.
Setting `investment_variable_type = none` can be used to disable investments
regardless of [investment\_count\_max\_cumulative](@ref).
See the following for more details for connections and units, respectively.

Connection: The [investment\_variable\_type](@ref) parameter represents the *type* of the 
[connections\_invested\_available](@ref) decision variable.
The default value, `linear`, means that any arbitrary fraction of [capacity\_per\_connection](@ref) can be invested in.
Meanwhile, `integer` and `binary` limit these according to their names, respectively.

Unit: Within an investment problem `investment_variable_type` determines the [unit](@ref) investment decision variable type.
Since the `unit_flow`s will be limited to the product of the investment variable and the corresponding 
[capacity\_per\_unit](@ref) for each `unit_flow` and since [investment\_count\_max\_cumulative](@ref) represents the upper 
bound of the investment decision variable, `investment_variable_type` thus determines what the investment decision represents.
If [investment\_variable\_type](@ref) is `integer` or `binary`, then [investment\_count\_max\_cumulative](@ref)
represents the maximum number of discrete units that may be invested.
If [investment\_variable\_type](@ref) is `linear` (default), `investment_count_max_cumulative` is more analogous to a capacity with [capacity\_per\_unit](@ref) being analogous to a scaling parameter.

For example, if `investment_variable_type` = `integer`, 
`investment_count_max_cumulative` = 4 and `capacity_per_unit` for a particular `unit_flow` = 400 MW, then the investment 
decision is how many 400 MW units to build. If `investment_variable_type` = linear, 
`investment_count_max_cumulative` = 400 and `capacity_per_unit` for a particular `unit_flow` = 1 MW, then the investment 
decision is how much capacity if this particular unit to build. Finally, if `investment_variable_type` = `integer`, 
`investment_count_max_cumulative` = 10 and `capacity_per_unit` for a particular `unit_flow` = 50 MW, then the investment 
decision is many 50MW blocks of capacity of this particular unit to build.

See also [Investment Optimization](@ref) and [investment\_count\_max\_cumulative](@ref)

## `is_non_spinning`

>**Related [Entity Classes](@ref):** [node](@ref)

By setting the parameter [is\_non\_spinning](@ref) to `true`, a node is treated as a non-spinning reserve node. Note that this is only to differentiate spinning from non-spinning reserves. It is still necessary to set [reserve\_active](@ref) to `true`.
The mathematical formulation holds a chapter on [Reserve constraints](@ref) and the general concept of setting up a model with reserves is described in [Reserves](@ref).

## `is_renewable`

>**Related [Entity Classes](@ref):** [unit](@ref)

A boolean value indicating whether a [unit](@ref) is a renewable energy source (RES).
If `true`, then the [unit](@ref) contributes to the share of the demand that is supplied by RES in the context of
[mp\_min\_res\_gen\_to\_demand\_ratio](@ref).
## `lead_time`

>**Related [Entity Classes](@ref):** [connection](@ref) and [unit](@ref)


## `lifetime_constraint_sense`

>**Related [Entity Classes](@ref):** [connection](@ref) and [unit](@ref)


## `lifetime_economic`

>**Related [Entity Classes](@ref):** [connection](@ref) and [unit](@ref)


## `lifetime_technical`

>**Related [Entity Classes](@ref):** [connection](@ref) and [unit](@ref)

Connection: Duration parameter that determines the minimum duration of `connection` investment decisions. Once a `connection` has been invested-in, it must remain invested-in for `lifetime_technical`.

Unit: Duration parameter that determines the minimum duration of `unit` investment decisions. Once a `unit` has been invested-in, it must remain invested-in for `lifetime_technical`.

Note that `lifetime_technical` is a dynamic parameter that will impact the amount of solution history that must remain available to the optimisation in each step - this may impact performance.

See also [Investment Optimization](@ref) and [investment\_count\_max\_cumulative](@ref)

## `mga_investment_active`

>**Related [Entity Classes](@ref):** [connection](@ref) and [unit](@ref)

The [mga\_investment\_active](@ref) is a boolean parameter that can be used in combination with the MGA algorithm 
(see [mga-advanced](@ref)). 

Connection: As soon as the value of [mga\_investment\_active](@ref) is set to `true`, investment decisions in this 
connection, or group of connections, will be included in the MGA algorithm.

Unit: As soon as the value of [mga\_investment\_active](@ref) is set to `true`, investment decisions in this unit, or 
group of units, will be included in the MGA algorithm.

## `mga_storage_investment_active`

>**Related [Entity Classes](@ref):** [node](@ref)

The [mga\_storage\_investment\_active](@ref) is a boolean parameter that can be used in combination with the MGA algorithm (see [mga-advanced](@ref)). As soon as
the value of [mga\_storage\_investment\_active](@ref) is set to `true`, investment decisions in this connection, or group of storages, will be included in the MGA algorithm.

## `min_down_time`

>**Related [Entity Classes](@ref):** [unit](@ref)

The definition of the `min_down_time` parameter will trigger the creation of the [Constraint on minimum down time](@ref constraint_min_down_time). It sets a lower bound on the period that a unit has to stay offline after a shutdown.

It can be defined for a [unit](@ref) and will then impose restrictions on the [units\_on](@ref) variables that represent the on- or offline status of the unit. The parameter is given as a duration value. When the parameter is not included, the aforementioned constraint will not be created, which is equivalent to choosing a value of 0.

For a more complete description of unit commmitment restrictions, see [Unit commitment](@ref).

## `min_up_time`

>**Related [Entity Classes](@ref):** [unit](@ref)

The definition of the `min_up_time` parameter will trigger the creation of the [Constraint on minimum up time](@ref constraint_min_up_time). It sets a lower bound on the period that a unit has to stay online after a startup.

It can be defined for a [unit](@ref) and will then impose restrictions on the [units\_on](@ref) variables that represent the on- or offline status of the unit. The parameter is given as a duration value. When the parameter is not included, the aforementioned constraint will not be created, which is equivalent to choosing a value of 0.

For a more complete description of unit commmitment restrictions, see [Unit commitment](@ref).

## `minimum_reserve_activation_time`

>**Related [Entity Classes](@ref):** [node](@ref)

The parameter [minimum\_reserve\_activation\_time](@ref) is the duration
a reserve product needs to be online, before it can be replaced by another (slower) reserve product.

In SpineOpt, the parameter is used to model reserve provision through storages. If a storage provides
reserves to a reserve [node](@ref) (see also [reserve\_active](@ref)) one needs to ensure that the node state
is sufficiently high to provide these scheduled reserves as least for the duration of the [minimum\_reserve\_activation\_time](@ref).
The [constraint on the minimum node state with reserve provision](@ref constraint_res_minimum_node_state) is triggered by the existence of the [minimum\_reserve\_activation\_time](@ref). See also [Reserves](@ref)

## `model_algorithm`

>**Related [Entity Classes](@ref):** [model](@ref)


## `model_end`

>**Related [Entity Classes](@ref):** [model](@ref)

Together with the [model_start](@ref) parameter, it is used to define the temporal horizon of the model. In case of a single solve optimization, the parameter marks the end of the last timestep that is possibly part of the optimization. Note that it poses an upper bound, and that the optimization does not necessarily include this timestamp when the [block_end](@ref) parameters are more stringent.

In case of a rolling horizon optimization, it will tell to the model to stop rolling forward once an optimization has been performed for which the result of the indicated timestamp has been kept in the final results. For example, assume that a `model_end` value of `2030-01-01T05:00:00` has been chosen, a [block_end](@ref) of `3h`, and a [roll_forward](@ref) of `2h`. The [roll_forward](@ref) parameter indicates here that the results of the first two hours of each optimization window are kept as final, therefore the last optimization window will span the timeframe `[2030-01-01T04:00:00 - 2030-01-01T06:00:00]`.

A DateTime value should be chosen for this parameter. 

## `model_start`

>**Related [Entity Classes](@ref):** [model](@ref)

Together with the [model_end](@ref) parameter, it is used to define the temporal horizon of the model. For a single solve optimization, it marks the timestamp from which the relative offset in a [temporal_block](@ref) is defined by the [block_start](@ref) parameter. In the rolling optimization framework, it does this for the first optimization window.

A DateTime value should be chosen for this parameter. 

## `model_type`

>**Related [Entity Classes](@ref):** [model](@ref)

This parameter controls the low-level algorithm that SpineOpt uses to solve the underlying optimization problem.
Currently three values are possible:

`spineopt_standard` uses the standard algorithm.

`spineopt_benders` uses the Benders decomposition algorithm (see [Decomposition](@ref decomposition).

`spineopt_mga` uses the Model to Generate Alternatives algorithm.

## `monitoring_active`

>**Related [Entity Classes](@ref):** [connection](@ref)

When using ptdf-based load flow by setting [physics\_type](@ref) to either [ptdf\_physics](@ref grid_physics_list) or [ptdf\_physics](@ref grid_physics_list), a constraint is created for each connection for which `monitoring_active` = `true`. Thus, to monitor the ptdf-based flow on a particular connection `monitoring_active` must be set to `true`.

See also [powerflow](@ref ptdf-based-powerflow)

## `node_opf_type`

>**Related [Entity Classes](@ref):** [node](@ref)

Used to identify the reference node (or slack bus) when ptdf based dc load flow is enabled ([physics\_type](@ref) set to [ptdf\_physics](@ref grid_physics_list) or [lodf\_physics](@ref grid_physics_list). To identify the reference node, set `node_opf_type` = `:node_opf_type_reference`

See also [powerflow](@ref ptdf-based-powerflow).

## `online_variable_type`

>**Related [Entity Classes](@ref):** [unit](@ref)

`online_variable_type` is a method parameter to model the 'commitment' or 'activation' of a [unit](@ref),
that is the situation where the unit becomes online and active in the system. It can take the values "binary", "integer", "linear" and "none".

If `binary`, then the commitment is modelled as an online/offline decision (classic unit commitment).

If `integer`, then the commitment is modelled as the number of units that are online (clustered unit commitment). 

If `linear`, then the commitment is modelled as the number of units that are online, but here it is also possible to activate 'fractions' of a unit.
This should reduce computational burden compared to `integer`.
Note that `linear` is a special case for which online variables are omitted if they are deemed unnecessary by the preprocessing.

If `none`, then the committment is not modelled at all and the unit is assumed to be always online. This reduces the computational burden the most.

## `operating_points`

>**Related [Entity Classes](@ref):** [unit\_\_to\_node](@ref)

If `operating_points` is defined as an array type on a certain `unit__to_node` or `node__to_unit` flow, the corresponding `unit_flow` flow variable is decomposed into a number of sub operating segment variables, `unit_flow_op` one for each operating segment, with an additional index, `i` to reference the specific operating segment. Each value in the array represents the upper bound of the operating segment, normalized on `capacity_per_unit` for the corresponding `unit__to_node` or `node__to_unit` flow. `operating_points` is used in conjunction with [fix\_ratio\_in\_out\_unit\_flow](@ref) where the array dimension must match and is used to define the normalized operating point bounds for the corresponding incremental ratio. `operating_points` is also used in conjunction with [user\_constraint](@ref) where the array dimension must match any corresponding piecewise linear [coefficient\_for\_unit\_flow](@ref). Here `operating_points` is used also to define the normalized operating point bounds for the corresponding [coefficient\_for\_unit\_flow](@ref)s.

Note that `operating_points` is defined on a capacity-normalized basis and the values represent the upper bound of the corresponding operating segment variable. So if `operating_points` is specified as [0.5, 1], this creates two operating segments, one from zero to 50% of the corresponding [capacity\_per\_unit](@ref) and a second from 50% to 100% of the corresponding [capacity\_per\_unit](@ref).
## `ordered_unit_flow_op`

>**Related [Entity Classes](@ref):** [node\_\_to\_unit](@ref) and [unit\_\_to\_node](@ref)

If one defines the parameter `ordered_unit_flow_op` in a `node__to_unit` or `unit__to_node` relationship, SpineOpt will create variable `unit_flow_op_active` to order each `unit_flow_op` of the `unit_flow` according to the rank of defined [operating\_points](@ref). This setting is only necessary when the segmental `unit_flow_op`s are with increasing conversion efficiency. The numerical type of `unit_flow_op_active` (float, binary, or integer) follows that of variable `units_on` which can be set via parameter [online\_variable\_type](@ref).

Note that this functionality is based on SOS2 constraints so only a MILP configuration, i.e. make variable `unit_flow_op_active` a binary or integer, guarantees correct performance.

## `outage_variable_type`

>**Related [Entity Classes](@ref):** [unit](@ref)

`outage_variable_type` is a method parameter to model the 'commitment' or 'activation' of [unit](@ref) maintenance outages.

To scheduled maintenance outages, one must activate the [units\_out\of\_service](@ref) variable. This is done by changing the value of the [outage\_variable\_type](@ref) to either `integer` (for clustered units) or `binary` for binary units or `linear` for continuous units. Setting [outage\_variable\_type](@ref) to `none` will deactivate the [units\_out\of\_service](@ref) variable and this is the default value.
## `output_db_url`

>**Related [Entity Classes](@ref):** [report](@ref)

The [output\_db\_url](@ref) parameter is the url of the databse to write the results of the model run.
It overrides the value of the second argument passed to `run_spineopt`.
## `output_resolution`

>**Related [Entity Classes](@ref):** [output](@ref), [stage\_\_output\_\_connection](@ref), [stage\_\_output\_\_node](@ref), [stage\_\_output\_\_unit](@ref) and [stage\_\_output](@ref)

The [output\_resolution](@ref) parameter indicates the resolution at which [output](@ref) values should be reported.

If `null` (the default), then results are reported at the highest available resolution from the model.
If `output_resolution` is a duration value, then results are aggregated at that resolution before being reported.
At the moment, the aggregation is simply performed by taking the average value.

## `output_type`

>**Related [Entity Classes](@ref):** [output](@ref)


## `overwrite_results_on_rolling`

>**Related [Entity Classes](@ref):** [report\_\_output](@ref)

The [overwrite\_results\_on\_rolling](@ref) parameter allows one to define whether or not results
from further optimisation windows should overwrite those from previous ones.
This, of course, is relevant only if optimisation windows overlap,
which in turn happens whenever a [temporal\_block](@ref) goes beyond the end of the window.

If `true` (the default) then results are written as a time-series.
If `false`, then results are written as a map from analysis time (i.e., the window start) to time-series.
## `physics_duration`

>**Related [Entity Classes](@ref):** [grid](@ref)

This parameter determines the duration, relative to the start of the optimisation window,
over which the physics determined by [physics\_type](@ref) should be applied.
This is useful when the optimisation window includes a long look-ahead where the detailed physics are not
necessary. In this case one can set `physics_duration` to a shorter value to reduce problem size
and increase performace.

This parameter is currently only used with `ptdf_physics` and `lodf_physics`.

See also [powerflow](@ref ptdf-based-powerflow)

## `physics_type`

>**Related [Entity Classes](@ref):** [grid](@ref)

This parameter determines the specific formulation used to carry out flow calculations within a model. 

To enable power transfer distribution factor (ptdf) based dc load flow for a network of [node](@ref)s and 
[connection](@ref)s, all [node](@ref)s must be related to a [grid](@ref) with [physics\_type](@ref) set to 
[ptdf\_physics](@ref grid_physics_list). To enable security constraint unit comment based on ptdfs and line outage 
distribution factors (lodf) all [node](@ref)s must be related to a [grid](@ref) with [physics\_type](@ref) set to 
[lodf\_physics](@ref grid_physics_list). See also [powerflow](@ref ptdf-based-powerflow).

To enable node-based lossless DC powerflow, each node will be associated with a [node\_voltage\_angle](@ref) variable. 
To enable the generation of the variable in the optimization model, all [node](@ref)s must be related to a [grid](@ref) 
with [physics\_type](@ref) set to [voltage\_angle\_physics](@ref grid_physics_list). The voltage angle at a certain node 
can also be constrained through the parameters [voltage\_angle\_max](@ref) and [voltage\_angle\_min](@ref). More details 
on the use of lossless nodal DC power flows are described [here](@ref Lossless-nodal-DC-power-flows).

To enable pressure driven gas network calculations, all [node](@ref)s must be related to a [grid](@ref) with 
[physics\_type](@ref) set to [pressure\_physics](@ref grid_physics_list), in order to trigger the generation of the 
[node\_pressure](@ref) variable. The pressure at a certain node can also be constrainted through the parameters 
[pressure\_max](@ref) and [pressure\_min](@ref). More details on the use of pressure driven gas transfer
are described [here](@ref pressure-driven-gas-transfer).

## `reserve_active`

>**Related [Entity Classes](@ref):** [node](@ref)

By setting the parameter [reserve\_active](@ref) to `true`, a node is treated as a
reserve [node](@ref) in the model. Units that are linked through a [unit\_\_to\_node](@ref)
relationship will be able to provide balancing services to the reserve node, but
within their technical feasibility. The mathematical formulation holds a chapter on [Reserve constraints](@ref)
and the general concept of setting up a model with reserves is described in [Reserves](@ref).

## `reserve_downward`

>**Related [Entity Classes](@ref):** [node](@ref)

If a [node](@ref) has a `true` [reserve\_active](@ref) parameter,
it will be treated as a reserve node in the model. To define whether
the node corresponds to an upward or downward reserve commodity, the [reserve\_upward](@ref) or the [reserve\_downward](@ref)
parameter needs to be set to true, respectively.

## `reserve_upward`

>**Related [Entity Classes](@ref):** [node](@ref)

If a [node](@ref) has a `true` [reserve\_active](@ref) parameter,
it will be treated as a reserve node in the model. To define whether
the node corresponds to an upward or downward reserve commodity, the [reserve\_upward](@ref) or the [reserve\_downward](@ref)
parameter needs to be set to `true`, respectively.

## `resolution`

>**Related [Entity Classes](@ref):** [temporal\_block](@ref)

This parameter specifies the resolution of the temporal block, or in other words: the length of the timesteps used in the optimization run. Generally speaking, variables and constraints are generated for each timestep of an optimization. For example, the nodal balance constraint must hold for each timestep.

An array of duration values can be used to have a resolution that varies with time itself. It can for example be used when uncertainty in one of the inputs rises as the optimization moves away from the model start. Think of a forecast of for instance wind power generation, which might be available in quarter hourly detail for one day in the future, and in hourly detail for the next two days. It is possible to take a quarter hourly resolution for the full horizon of three days. However, by lowering the temporal resolution after the first day, the computational burden is lowered substantially.

## `roll_forward`

>**Related [Entity Classes](@ref):** [model](@ref)

This parameter defines how much the optimization window rolls forward in a rolling horizon optimization and should be expressed as a duration. In a rolling horizon optimization, the model is split in windows that are optimized iteratively; `roll_forward` indicates how much the window should roll forward after each iteration. Overlap between consecutive optimization windows is possible. In the practical approaches presented in [Temporal Framework](@ref), the rolling window optimization will be explained in more detail. The default value of this parameter is the entire model time horizon, which leads to a single optimization for the entire time horizon.

In case you want your model to roll a different amount of time after each iteration, you can specify an array of durations for `roll_forward`. Position *i*th in this array indicates how much the model should roll after iteration *i*. This allows you to perform a rolling horizon optimization over a selection of disjoint representative periods as if they were contiguous.
## `solver_lp`

>**Related [Entity Classes](@ref):** [model](@ref)

Specifies the Julia solver package to be used to solve Linear Programming Problems (LPs) for the specific [model](@ref). 
The value must correspond exactly (case sensitive) to the name of the Julia solver package (e.g. `Clp.jl`). Installation and configuration of
solvers is the responsibility of the user. A full list of solvers supported by JuMP can be found [here](https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers). 
Note that the specified problem must support LP problems. Solver options are specified using the [solver\_lp\_options](@ref) parameter for the model.
Note also that if `run_spineopt()` is called with the lp_solver keyword argument specified, this will override this parameter.
## `solver_lp_options`

>**Related [Entity Classes](@ref):** [model](@ref)

LP solver options are specified for a model using the [solver\_lp\_options](@ref) parameter. This parameter value must take the form of a nested map
where the outer key corresponds to the solver package name (case sensitive). E.g. `Clp.jl`. The inner map consists of option name and value pairs. See the below example. 
By default, the SpineOpt template contains some common parameters for some common solvers. For a list of supported solver options, one should consult
the documentation for the solver and//or the julia solver wrapper package.
![example solver_lp_options map parameter](https://user-images.githubusercontent.com/7080191/155577992-b9dbf284-390b-4df4-b4f3-52b5d0a603d9.png)
## `solver_mip`

>**Related [Entity Classes](@ref):** [model](@ref)

Specifies the Julia solver package to be used to solve Mixed Integer Programming Problems (MIPs) for the specific [model](@ref). 
The value must correspond exactly (case sensitive) to the name of the Julia solver package (e.g. `Cbc.jl`). Installation and configuration of
solvers is the responsibility of the user. A full list of solvers supported by JuMP can be found [here](https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers). 
Note that the specified problem must support MIP problems. Solver options are specified using the [solver\_mip\_options](@ref) parameter for the model.
Note also that if `run_spineopt()` is called with the mip_solver keyword argument specified, this will override this parameter.
## `solver_mip_options`

>**Related [Entity Classes](@ref):** [model](@ref)

MIP solver options are specified for a model using the [solver\_mip\_options](@ref) parameter. This parameter value must take the form of a nested map
where the outer key corresponds to the solver package name (case sensitive). E.g. `Cbc.jl`. The inner map consists of option name and value pairs. See the below example. 
By default, the SpineOpt template contains some common parameters for some common solvers. For a list of supported solver options, one should consult
the documentation for the solver and//or the julia solver wrapper package.
![example solver_mip_options map parameter](https://user-images.githubusercontent.com/7080191/155577992-b9dbf284-390b-4df4-b4f3-52b5d0a603d9.png)
## `stochastic_scenario_end`

>**Related [Entity Classes](@ref):** [stochastic\_structure\_\_stochastic\_scenario](@ref)

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
## `storage_active`

>**Related [Entity Classes](@ref):** [node](@ref)

The [storage\_active](@ref) parameter determines whether the [node](@ref) has a [node\_state](@ref) variable generated for 
it that can increase and decrease based on the flows entering and leaving the [node](@ref), allowing for commodity 
storage at the [node](@ref).

The default value is `false`, meaning that the node cannot store the commodity. Define the value as `true` to allow for commodity storage.

Note that you'll also have to specify a value for the [storage_state_coefficient](@ref) parameter,
as otherwise the [node\_state](@ref) variable has zero commodity capacity.
## `storage_decommissioning_time`

>**Related [Entity Classes](@ref):** [node](@ref)


## `storage_investment_variable_type`

>**Related [Entity Classes](@ref):** [node](@ref)

Within an investment problem `storage_investment_variable_type` determines the storage investment decision variable type.
Since a [node](@ref)'s `node_state` will be limited to the product of the investment variable and the corresponding [storage\_state\_max](@ref) and since [storage\_investment\_count\_max\_cumulative](@ref) represents the upper bound of the storage investment decision variable,
`storage_investment_variable_type` thus determines what the investment decision represents.

Setting `storage_investment_variable_type = none` disables investment decisions regardless of [storage\_investment\_count\_max\_cumulative](@ref).
If [storage\_investment\_variable\_type](@ref) is integer or binary, then [storage\_investment\_count\_max\_cumulative](@ref) represents the maximum number of discrete storages that may be invested-in. If [storage\_investment\_variable\_type](@ref) is linear (default), `storage_investment_count_max_cumulative` is more analogous to a capacity with [storage\_state\_max](@ref) being analogous to a scaling parameter. For example, if `storage_investment_variable_type` = `integer`, `storage_investment_count_max_cumulative` = 4 and `storage_state_max` = 1000 MWh, then the investment decision is how many 1000h MW storages to build. If `storage_investment_variable_type` = linear, `storage_investment_count_max_cumulative` = 1000 and `storage_state_max` = 1 MWh, then the investment decision is how much storage capacity to build. Finally, if `storage_investment_variable_type` = `integer`, `storage_investment_count_max_cumulative` = 10 and `storage_state_max` = 100 MWh, then the investment decision is how many 100MWh storage blocks to build.

See also [Investment Optimization](@ref) and [storage\_investment\_count\_max\_cumulative](@ref).

## `storage_lead_time`

>**Related [Entity Classes](@ref):** [node](@ref)


## `storage_lifetime_constraint_sense`

>**Related [Entity Classes](@ref):** [node](@ref)


## `storage_lifetime_economic`

>**Related [Entity Classes](@ref):** [node](@ref)


## `storage_lifetime_technical`

>**Related [Entity Classes](@ref):** [node](@ref)

Duration parameter that determines the minimum duration of storage investment decisions. Once a storage has been invested-in, it must remain invested-in for `storage_lifetime_technical`. Note that `storage_lifetime_technical` is a dynamic parameter that will impact the amount of solution history that must remain available to the optimisation in each step - this may impact performance.

See also [Investment Optimization](@ref) and [storage\_investment\_count\_max\_cumulative](@ref)

## `storage_longterm_active`

>**Related [Entity Classes](@ref):** [node](@ref)


## `tight_compact_formulations_active`

>**Related [Entity Classes](@ref):** [model](@ref)


## `unit_flow_non_anticipativity_time`

>**Related [Entity Classes](@ref):** [node\_\_to\_unit](@ref) and [unit\_\_to\_node](@ref)


## `units_on_non_anticipativity_time`

>**Related [Entity Classes](@ref):** [unit](@ref)

The [units\_on\_non\_anticipativity\_time](@ref) parameter defines the duration, starting from the begining
of the optimisation window, where [units\_on](@ref) variables need to be fixed to the result of the previous window.

This is intended to model "slow" units whose commitment decision needs to be taken in advance, e.g., in "day-ahead" mode,
and cannot be changed afterwards.

## `version`

>**Related [Entity Classes](@ref):** [settings](@ref)


## `weight`

>**Related [Entity Classes](@ref):** [temporal\_block](@ref)

The `weight` variable, defined for a [temporal_block](@ref) object can be used to assign different weights to different temporal periods that are modeled. It basically determines how important a certain temporal period is in the total cost, as it enters the [Objective](@ref) function. The main use of this parameter is for representative periods, where each representative period represents a specific fraction of a year or so.  

## `weight_relative_to_parents`

>**Related [Entity Classes](@ref):** [stochastic\_structure\_\_stochastic\_scenario](@ref)

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
## `window_duration`

>**Related [Entity Classes](@ref):** [model](@ref)


## `write_lodf_file`

>**Related [Entity Classes](@ref):** [model](@ref)

If this parameter value is set to `true`, a diagnostics file containing all the network line outage distributions factors in CSV format will be written to the current directory.
## `write_mps_file`

>**Related [Entity Classes](@ref):** [model](@ref)

This parameter is deprecated and will be removed in a future version.

This parameter controls when to write a diagnostic model file in MPS format. If set to `write_mps_always`, the model will always be written in MPS format to the current directory. If set to `write\_mps\_on\_no\_solve`, the MPS file will be written when the model solve terminates with a status of false.  If set to `write\_mps\_never`, no file will be written

## `write_ptdf_file`

>**Related [Entity Classes](@ref):** [model](@ref)

If this parameter value is set to `true`, a diagnostics file containing all the network power transfer distributions factors in CSV format will be written to the current directory.