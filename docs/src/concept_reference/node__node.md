The [node\_\_node](@ref) relationship is used for defining direct interactions between two [node](@ref)s,
like diffusion of [commodity](@ref) content.
Note that the [node\_\_node](@ref) relationship is assumed to be one-directional,
meaning that
```julia
node__node(node1=n1, node2=n2) != node__node(node1=n2, node2=n1).
```
Thus, when one wants to define *symmetric relationships* between two [node](@ref)s,
one needs to define both directions as separate relationships.