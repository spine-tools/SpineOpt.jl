The definition of the [fix\_ratio\_in\_out\_unit\_flow](@ref) parameter triggers the generation of the
[constraint\_fix\_ratio\_in\_out\_unit\_flow](@ref ratio_unit_flow) and fixes the ratio between incoming and outgoing flows of a unit.
The parameter is defined on the relationship class [unit\_\_node\_\_node](@ref),
where the first node (or group of nodes) in this relationship represents the `from_node`,i
i.e. the incoming flows to the unit, and the second node (or group of nodes),
represents the `to_node` i.e. the outgoing flow from the unit.
The ratio parameter is interpreted such that it constrains the ratio of `in` over `out`,
where `in` is the [unit\_flow](@ref) variable from the first [node](@ref) in the [unit\_\_node\_\_node](@ref) relationship
in a left-to-right order.

To enforce e.g. a fixed ratio of `1.4` for a unit `u` between its incoming gas flow from the node `ng` and its outgoing flows to the node group `el_heat` (consisting of the two nodes `el` and `heat`), the [fix\_ratio\_in\_out\_unit\_flow](@ref) parameter would be set to `1.4` for the relationship `u__ng__el_heat`.

To implement a piecewise linear ratio, the parameter should be specified as an array type. It is then used in conjunction with the [unit](@ref) parameter [operating\_points](@ref) which should also be defined as an array type of equal dimension. When defined as an array type, `fix\_ratio\_in\_out\_unit\_flow`[i] is the effective incremental ratio between [operating\_points](@ref) [i-1] \(or zero if i=1\) and [operating\_points](@ref)[i]. Note that [operating\_points](@ref) is defined on a capacity-normalized basis so if [operating\_points](@ref) is specified as [0.5, 1], this creates two operating segments, one from zero to 50% of the corresponding [unit\_capacity](@ref) and a second from 50% to 100% of the corresponding [unit\_capacity](@ref). Note also that the formulation assumes a convex, monotonically increasing function. The formulation relies on optimality to load the segments in the correct order and no additional integer variables are created to enforce the correct loading order.
