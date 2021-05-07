Used to control specific pre-processing actions on connections. Currently, the primary purpose of `connection_type` is to simplify the data that is required to define a simple bi-directional, lossless line. If `connection_type`=`:connection_type_lossless_bidirectional`, it is only necessary to specify the following minimum data:
 - relationship: [connection__from_node](@ref)
 - relationship: [connection__to_node](@ref)
 - parameter: [connection_capacity](@ref) (defined on [connection__from_node](@ref) and/or [connection__to_node](@ref))
If `connection_type`=`:connection_type_lossless_bidirectional` the following pre-processing actions are taken:
 - reciprocal [connection__from_node](@ref) and [connection__to_node](@ref) relationships are created if they don't exist
 - a new [connection\_\_node\_\_node](@ref) relationship is created if none exists already
 - [fix\_ratio\_out\_in\_connection\_flow](@ref) parameter is created with the value of 1 if no existing parameter found (therefore this value can be overridden)
 - The first [connection_capacity](@ref) parameter found is copied to [connection__from_node](@ref)s and [connection__to_node](@ref)s without a defined [connection_capacity](@ref).
