The definition of the [fix\_ratio\_out\_in\_connection\_flow](@ref) parameter triggers the generation of the
[constraint\_fix\_ratio\_out\_in\_connection\_flow](@ref constraint_ratio_out_in_connection_flow)
and fixes the ratio between outgoing and incoming flows of a connection.
The parameter is defined on the relationship class [connection\_\_node\_\_node](@ref),
where the first node (or group of nodes) in this relationship represents the `to_node`,
i.e. the outgoing flow from the [connection](@ref), and the second node (or group of nodes),
represents the `from_node`, i.e. the incoming flows to the [connection](@ref).
In most cases the [fix\_ratio\_out\_in\_connection\_flow](@ref) parameter is set to equal or lower than `1`,
linking the flows entering to the flows leaving the connection.
The ratio parameter is interpreted such that it constrains the ratio of `out` over `in`,
where `out` is the [connection\_flow](@ref) variable from the first [node](@ref) in the [connection\_\_node\_\_node](@ref) relationship
in a left-to-right order.
The parameter can be used to e.g. account for losses over a connection in a certain direction.

To enforce e.g. a fixed ratio of `0.8` for a connection `conn` between its outgoing electricity flow to [node](@ref) `el1` and its incoming flows from the node [node](@ref) `el2`, the [fix\_ratio\_out\_in\_connection\_flow](@ref) parameter would be set to `0.8` for the relationship `u__el1__el2`.
