The [flow_limits_fix](@ref) parameter fixes the value of the [unit_flow](@ref) or [connection_flow](@ref) variable.

For units, If [operating\_points](@ref) is defined on a certain `unit__to_node` or `node__to_unit` flow, the corresponding `unit_flow` flow variable is decomposed into a number of sub-variables, `unit_flow_op` one for each operating point, with an additional index, `i` to reference the specific operating point. `flow_limits_fix_op` can thus be used to fix the value of one or more of the variables as desired.

> **Warning:** that this parameter should be set to 0 for history timeslices to avoid free energy in the model when using the [connection_flow_delay](@ref) parameter.