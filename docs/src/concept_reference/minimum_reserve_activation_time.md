The parameter [minimum\_reserve\_activation\_time](@ref) is the duration
a reserve product needs to be online, before it can be replaced by another (slower) reserve product.

In SpineOpt, the parameter is used to model reserve provision through storages. If a storage provides
reserves to a reserve [node](@ref) (see also [is\_reserve\_node](@ref)) one needs to ensure that the node state
is sufficiently high to provide these scheduled reserves as least for the duration of the [minimum\_reserve\_activation\_time](@ref).
The [constraint on the minimum node state with reserve provision](@ref constraint_res_minimum_node_state) is triggered by the existence of the [minimum\_reserve\_activation\_time](@ref). See also [Reserves](@ref)
