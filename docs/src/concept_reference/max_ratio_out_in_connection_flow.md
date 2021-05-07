The definition of the [max\_ratio\_out\_in\_connection\_flow](@ref) parameter triggers the generation of the
[constraint\_max\_ratio\_out\_in\_connection\_flow](@ref constraint_ratio_out_in_connection_flow)
and sets an upper bound on the ratio between outgoing and incoming flows of a connection.
The parameter is defined on the relationship class [connection\_\_node\_\_node](@ref),
where the first node (or group of nodes) in this relationship represents the `to_node`,
i.e. the outgoing flow from the connection, and the second node (or group of nodes),
represents the `from_node`, i.e. the incoming flows to the connection.
The ratio parameter is interpreted such that it constrains the ratio of `out` over `in`,
where `out` is the [connection\_flow](@ref) variable from the first [node](@ref) in the [connection\_\_node\_\_node](@ref) relationship
in a left-to-right reading order.

To enforce e.g. a maximum ratio of `0.8` for a connection `conn` between its outgoing electricity flow to [node](@ref) `commodity1` and its incoming flows from the node [node](@ref) `commodity2`, the [max\_ratio\_out\_in\_connection\_flow](@ref) parameter would be set to `0.8` for the relationship `conn__commodity1__commodity2`.

Note that the ratio can also be defined for [connection\_\_node\_\_node](@ref) relationships where one or both of the nodes correspond to node groups in order to impose a ratio on aggregated connection flows.