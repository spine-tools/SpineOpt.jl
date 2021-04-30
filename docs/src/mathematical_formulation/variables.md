# Variables
## `binary_gas_connection_flow`

 > **Math symbol:** ``v_{binary\_gas\_connection\_flow} ``

 > **Indices:** (connection=conn, node=n, direction=d, stochastic_scenario=s, t=t)

 > **Indices function:** binary\_gas\_connection\_flow\_indices

Binary variable with the indices node ``n`` over the connection ``conn`` in the direction ``to\_node`` for the stochastic scenario ``s`` at timestep ``t`` describing if the direction of gas flow for a pressure drive gas transfer is in the indicated direction.  

## `connection_flow `

 > **Math symbol:** ``v_{connection\_flow } ``

 > **Indices:** (connection=conn, node=n, direction=d, stochastic_scenario=s, t=t)

 > **Indices function:** connection\_flow\_indices

Commodity flow associated with node ``n`` over the connection ``conn`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t``

## `connection_intact_flow`

 > **Math symbol:** ``v_{connection\_intact\_flow} ``

 > **Indices:** (connection=conn, node=n, direction=d, stochastic_scenario=s, t=t)

 > **Indices function:** connection\_intact\_flow\_indices

Represents the ptdf-based flow on connections where all investment candidate connections are present in the network.

## `connections_decommissioned`

 > **Math symbol:** ``v_{connections\_decommissioned} ``

 > **Indices:** (connection=conn, stochastic_scenario=s, t=t)

 > **Indices function:** connections\_invested\_available\_indices

Number of decomissioned connections ``conn`` for the stochastic scenario ``s`` at timestep ``t``

## `connections_invested`

 > **Math symbol:** ``v_{connections\_invested} ``

 > **Indices:** (connection=conn, stochastic_scenario=s, t=t)

 > **Indices function:** connections\_invested\_available\_indices

Number of connections ``conn`` invested at timestep ``t`` in for the stochastic scenario ``s``

## `connections_invested_available`

 > **Math symbol:** ``v_{connections\_invested\_available} ``

 > **Indices:** (connection=conn, stochastic_scenario=s, t=t)

 > **Indices function:** connections\_invested\_available\_indices

Number of invested connections ``conn``  that are available still the stochastic scenario ``s`` at timestep ``t``

## `mp_objective_lowerbound_indices`

 > **Math symbol:** ``v_{mp\_objective\_lowerbound\_indices} ``

 > **Indices:** (t=t)

 > **Indices function:** mp\_objective\_lowerbound\_indices

Updating lowerbound for master problem of Benders decomposition

## `node_injection`

 > **Math symbol:** ``v_{node\_injection} ``

 > **Indices:** (node=n, stochastic_scenario=s, t=t)

 > **Indices function:** node\_injection\_indices

Commodity injections at node ``n`` for the stochastic scenario ``s`` at timestep ``t``

## `node_pressure`

 > **Math symbol:** ``v_{node\_pressure} ``

 > **Indices:** (node=n, stochastic_scenario=s, t=t)

 > **Indices function:** node\_pressure\_indices

Pressue at a node ``n`` for a specific stochastic scenario ``s``  and timestep ``t``. See also: [has\_pressure](@ref)

## `node_slack_neg`

 > **Math symbol:** ``v_{node\_slack\_neg} ``

 > **Indices:** (node=n, stochastic_scenario=s, t=t)

 > **Indices function:** node\_slack\_indices

Negative slack variable at node ``n`` for the stochastic scenario ``s`` at timestep ``t``

## `node_slack_pos`

 > **Math symbol:** ``v_{node\_slack\_pos} ``

 > **Indices:** (node=n, stochastic_scenario=s, t=t)

 > **Indices function:** node\_slack\_indices

Positive slack variable at node ``n`` for the stochastic scenario ``s`` at timestep ``t``

## `node_state`

 > **Math symbol:** ``v_{node\_state} ``

 > **Indices:** (node=n, stochastic_scenario=s, t=t)

 > **Indices function:** node\_state\_indices

Storage state at node ``n`` for the stochastic scenario ``s`` at timestep ``t``

## `node_voltage_angle`

 > **Math symbol:** ``v_{node\_voltage\_angle} ``

 > **Indices:** (node=n, stochastic_scenario=s, t=t)

 > **Indices function:** node\_voltage\_angle\_indices

Voltage angle at a node ``n`` for a specific stochastic scenario ``s``  and timestep ``t``. See also: [has\_voltage\_angle](@ref)

## `nonspin_ramp_down_unit_flow`

 > **Math symbol:** ``v_{nonspin\_ramp\_down\_unit\_flow} ``

 > **Indices:** (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)

 > **Indices function:** nonspin\_ramp\_down\_unit\_flow\_indices

Non-spinning downward reserve commodity flows of unit ``u`` at node ``n``  in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t``

## `nonspin_ramp_up_unit_flow`

 > **Math symbol:** ``v_{nonspin\_ramp\_up\_unit\_flow} ``

 > **Indices:** (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)

 > **Indices function:** nonspin\_ramp\_up\_unit\_flow\_indices

Non-spinning upward reserve commodity flows of unit ``u`` at node ``n``  in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t``

## `nonspin_units_shut_down`

 > **Math symbol:** ``v_{nonspin\_units\_shut\_down} ``

 > **Indices:** (unit=u, node=n, stochastic_scenario=s, t=t)

 > **Indices function:** nonspin\_units\_shut\_down\_indices

Number of units ``u`` held available for non-spinning downward reserve provision via shutdown to node ``n``  for the stochastic scenario ``s`` at timestep ``t``

## `nonspin_units_started_up`

 > **Math symbol:** ``v_{nonspin\_units\_started\_up} ``

 > **Indices:** (unit=u, node=n, stochastic_scenario=s, t=t)

 > **Indices function:** nonspin\_units\_started\_up\_indices

Number of units ``u`` held available for non-spinning upward reserve provision via startup to node ``n``  for the stochastic scenario ``s`` at timestep ``t``

## `ramp_down_unit_flow`

 > **Math symbol:** ``v_{ramp\_down\_unit\_flow} ``

 > **Indices:** (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)

 > **Indices function:** ramp\_down\_unit\_flow\_indices

Spinning downward ramp commodity flow associated with node ``n`` of unit ``u``  with node ``n`` over the connection ``conn`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t``

## `ramp_up_unit_flow`

 > **Math symbol:** ``v_{ramp\_up\_unit\_flow} ``

 > **Indices:** (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)

 > **Indices function:** ramp\_up\_unit\_flow\_indices

Spinning upward ramp commodity flow associated with node ``n`` of unit ``u``  with node ``n`` over the connection ``conn`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t``

## `shut_down_unit_flow`

 > **Math symbol:** ``v_{shut\_down\_unit\_flow} ``

 > **Indices:** (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)

 > **Indices function:** shut\_down\_unit\_flow\_indices

Downward ramp commodity flow during shutdown associated with node ``n`` of unit ``u``  with node ``n`` over the connection ``conn`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t``

## `start_up_unit_flow`

 > **Math symbol:** ``v_{start\_up\_unit\_flow} ``

 > **Indices:** (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)

 > **Indices function:** start\_up\_unit\_flow\_indices

Upward ramp commodity flow during start-up associated with node ``n`` of unit ``u``  with node ``n`` over the connection ``conn`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t``

## `storages_decommissioned`

 > **Math symbol:** ``v_{storages\_decommissioned} ``

 > **Indices:** (node=n, stochastic_scenario=s, t=t)

 > **Indices function:** storages\_invested\_available\_indices

Number of decomissioned storage nodes ``n`` for the stochastic scenario ``s`` at timestep ``t``

## `storages_invested`

 > **Math symbol:** ``v_{storages\_invested} ``

 > **Indices:** (node=n, stochastic_scenario=s, t=t)

 > **Indices function:** storages\_invested\_available\_indices

Number of storage nodes `` n`` invested in  at timestep ``t`` for the stochastic scenario ``s``

## `storages_invested_available`

 > **Math symbol:** ``v_{storages\_invested\_available} ``

 > **Indices:** (node=n, stochastic_scenario=s, t=t)

 > **Indices function:** storages\_invested\_available\_indices

Number of invested storage nodes ``n``  that are available still the stochastic scenario ``s`` at timestep ``t``

## `unit_flow`

 > **Math symbol:** ``v_{unit\_flow} ``

 > **Indices:** (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)

 > **Indices function:** unit\_flow\_indices

Commodity flow associated with node ``n`` over the unit ``u`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t``

## `unit_flow_op`

 > **Math symbol:** ``v_{unit\_flow\_op} ``

 > **Indices:** (unit=u, node=n, direction=d, i=i, stochastic_scenario=s, t=t)

 > **Indices function:** unit\_flow\_op\_indices

Contribution of the unit flow assocaited with operating point i

## `units_available`

 > **Math symbol:** ``v_{units\_available} ``

 > **Indices:** (unit=u, stochastic_scenario=s, t=t)

 > **Indices function:** units\_on\_indices

Number of available units ``u`` for the stochastic scenario ``s`` at timestep ``t``

## `units_invested`

 > **Math symbol:** ``v_{units\_invested} ``

 > **Indices:** (unit=u, stochastic_scenario=s, t=t)

 > **Indices function:** units\_invested\_available\_indices

Number of units ``u`` for the stochastic scenario ``s``  invested in at timestep ``t``

## `units_invested_available`

 > **Math symbol:** ``v_{units\_invested\_available} ``

 > **Indices:** (unit=u, stochastic_scenario=s, t=t)

 > **Indices function:** units\_invested\_available\_indices

Number of invested units ``u``  that are available still the stochastic scenario ``s`` at timestep ``t``

## `units_mothballed`

 > **Math symbol:** ``v_{units\_mothballed} ``

 > **Indices:** (unit=u, stochastic_scenario=s, t=t)

 > **Indices function:** units\_invested\_available\_indices

Number of units ``u`` for the stochastic scenariocenario ``s``  mothballed at timestep ``t``

## `units_on`

 > **Math symbol:** ``v_{units\_on} ``

 > **Indices:** (unit=u, stochastic_scenario=s, t=t)

 > **Indices function:** units\_on\_indices

Number of online units ``u`` for the stochastic scenario ``s`` at timestep ``t``

## `units_shut_down`

 > **Math symbol:** ``v_{units\_shut\_down} ``

 > **Indices:** (unit=u, stochastic_scenario=s, t=t)

 > **Indices function:** units\_on\_indices

Number of units ``u`` for the stochastic scenario ``s`` that switched to offline status at timestep ``t``

## `units_started_up`

 > **Math symbol:** ``v_{units\_started\_up} ``

 > **Indices:** (unit=u, stochastic_scenario=s, t=t)

 > **Indices function:** units\_on\_indices

Number of units ``u`` for the stochastic scenario ``s`` that switched to online status at timestep ``t``
