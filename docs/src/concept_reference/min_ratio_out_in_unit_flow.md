The definition of the [min\_ratio\_out\_in\_unit\_flow] parameter triggers the generation of the
[constraint\_min\_ratio\_out\_in\_unit\_flow](@ref ratio_unit_flow) and corresponds to a lower bound of the ratio between out and incoming flows of a unit.
The parameter is defined on the relationship class [unit\_\_node\_\_node](@ref),
where the first node (or group of nodes) in this relationship represents the `to_node`, i.e. the outgoing flow from the unit,
and the second node (or group of nodes), represents the `from_node`, i.e. the incoming flows to the unit.
The ratio parameter is interpreted such that it constrains the ratio of `out` over `in`,
where `out` is the [unit\_flow](@ref) variable from the first [node](@ref) in the [unit\_\_node\_\_node](@ref) relationship
in a left-to-right reading order.

To enforce e.g. a minimum ratio of `0.8` for a unit `u` between its outgoing flows to the node group `el_heat` (consisting of the two nodes `el` and `heat`) and its incoming gas flow from `ng` the [min\_ratio\_out\_in\_unit\_flow](@ref) parameter would be set to `0.8` for the relationship `u__el_heat__ng`.
