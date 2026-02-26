Allows enforcing additional flow for the first `unit_flow` based on `units_started_up` via the `constraint_ratio_unit_flow`.
Note that this parameter doesn't affect the second `unit_flow`, as it temporarily alters the [enforced ratios of the unit flows in question](@ref ratio_unit_flow).

Original description prior to data structure updates (2025-12-11):

"Used to implement unit startup fuel consumption where node 1 is assumed to be input fuel and node 2 is assumed to be output electrical energy. This is a flow from node 1 that is incurred when the value of the variable units_started_up is 1 in the corresponding time period. This flow does not result in additional output flow at node 2."
