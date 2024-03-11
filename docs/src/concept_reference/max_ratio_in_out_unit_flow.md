The definition of the [max\_ratio\_in\_out\_unit\_flow](@ref) parameter triggers the generation of the
[constraint\_max\_ratio\_in\_out\_unit\_flow](@ref ratio_unit_flow) and sets an upper bound on the ratio between incoming and outgoing flows of a unit.
The parameter is defined on the relationship class [unit\_\_node\_\_node](@ref),
where the first node (or group of nodes) in this relationship represents the `from_node`, i.e. the incoming flows to the unit,
and the second node (or group of nodes), represents the `to_node` i.e. the outgoing flow from the unit.
The ratio parameter is interpreted such that it constrains the ratio of `in` over `out`,
where `in` is the [unit\_flow](@ref) variable from the first [node](@ref) in the [unit\_\_node\_\_node](@ref) relationship
in a left-to-right reading order.

To enforce e.g. a maximum ratio of `1.4` for a unit `u` between its incoming gas flow from the node `ng` and its outgoing flow to the node group `el_heat` (consisting of the two nodes `el` and `heat`), the [max\_ratio\_in\_out\_unit\_flow](@ref) parameter would be set to `1.4` for the relationship `u__ng__el_heat`.
