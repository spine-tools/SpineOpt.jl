The [diffusion\_coefficient](@ref) parameter represents diffusion of a [commodity](@ref) between the two [node](@ref)s
in the [node\_\_node](@ref) relationship.
It appears as a coefficient on the `node_state` variable in the [node injection](@ref constraint_node_injection) constraint,
essentially representing *diffusion power per unit of state*.
Note that the [diffusion\_coefficient](@ref) is interpreted as *one-directional*, meaning that if one defines
```julia
diffusion_coefficient(node1=n1, node2=n2),
```
there will only be diffusion from `n1` to `n2`, but not vice versa.
*Symmetric diffusion* is likely used in most cases, requiring defining the [diffusion\_coefficient](@ref) both ways
```julia
diffusion_coefficient(node1=n1, node2=n2) == diffusion_coefficient(node1=n2, node2=n1).
```
