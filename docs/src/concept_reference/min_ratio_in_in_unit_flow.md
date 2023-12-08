The definition of the [min\_ratio\_in\_in\_unit\_flow](@ref) parameter triggers the generation of the
[constraint\_min\_ratio\_in\_in\_unit\_flow](@ref ratio_unit_flow) and sets a lower bound for the ratio between incoming flows of a unit.
The parameter is defined on the relationship class [unit\_\_node\_\_node](@ref),
where both nodes (or group of nodes) in this relationship represent `from_node`s, i.e. the incoming flows to the unit.
The ratio parameter is interpreted such that it constrains the ratio of `in1` over `in2`,
where `in1` is the [unit\_flow](@ref) variable from the first [node](@ref) in the [unit\_\_node\_\_node](@ref) relationship
in a left-to-right reading order.
This parameter can be useful, for instance if a unit requires a specific commodity mix as a fuel supply.

To enforce e.g. for a unit `u` a minimum share of `0.2` of its incoming flow from the node `supply_fuel_1` compared to its incoming flow from the node group `supply_fuel_2` (consisting of the two nodes `supply_fuel_2_component_a` and `supply_fuel_2_component_b`) the [min\_ratio\_in\_in\_unit\_flow](@ref) parameter would be set to `0.2` for the relationship `u__supply_fuel_1__supply_fuel_2`.
