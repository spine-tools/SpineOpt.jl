The definition of the [fix\_ratio\_out\_out\_unit\_flow](@ref) parameter triggers the generation of the
[constraint\_fix\_ratio\_out\_out\_unit\_flow](@ref ratio_unit_flow) and fixes the ratio between outgoing flows of a unit.
The parameter is defined on the relationship class [unit\_\_node\_\_node](@ref),
where the nodes (or group of nodes) in this relationship represent the `to_node`'s', i.e. outgoing flow from the unit.
The ratio parameter is interpreted such that it constrains the ratio of `out1` over `out2`,
where `out1` is the [unit\_flow](@ref) variable from the first [node](@ref) in the [unit\_\_node\_\_node](@ref) relationship
in a left-to-right reading order.

To enforce a fixed ratio between two products of a unit `u`, e.g. fixing the share of produced electricity flowing to node `el`  to `0.4` of the production of heat flowing to node `heat`, the [fix\_ratio\_out\_out\_unit\_flow](@ref) parameter would be set to `0.4` for the relationship `u__el__heat`.
