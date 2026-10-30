If `true` (the default), the model captures the impact of [connection](@ref) investments on the power flows of the network. It does this with line outage distribution factors (LODF) and an additional variable, [connection\_intact\_flow](@ref var_connection_intact_flow), which is the hypothetical flow on a [connection](@ref) if all [connection](@ref) investments were in place. The impact of each connection is captured individually.

If the model has no candidate connections, i.e. no [connection](@ref) can be invested in, SpineOpt sets this parameter to `false` automatically, and the [connection\_intact\_flow](@ref var_connection_intact_flow) variables are not created.

See [Impact of connection investments on network characteristics](@ref), [Lossless nodal DC power flows](@ref) and [PTDF-Based Powerflow](@ref ptdf-based-powerflow).
