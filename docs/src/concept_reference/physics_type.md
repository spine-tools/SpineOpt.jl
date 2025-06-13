This parameter determines the specific formulation used to carry out flow calculations within a model. 

To enable power transfer distribution factor (ptdf) based dc load flow for a network of [node](@ref)s and 
[connection](@ref)s, all [node](@ref)s must be related to a [grid](@ref) with [physics\_type](@ref) set to 
[grid\_physics\_ptdf](@ref grid_physics_list). To enable security constraint unit comment based on ptdfs and line outage 
distribution factors (lodf) all [node](@ref)s must be related to a [grid](@ref) with [physics\_type](@ref) set to 
[grid\_physics\_lodf](@ref grid_physics_list). See also [powerflow](@ref ptdf-based-powerflow).

To enable node-based lossless DC powerflow, each node will be associated with a [node\_voltage\_angle](@ref) variable. 
To enable the generation of the variable in the optimization model, all [node](@ref)s must be related to a [grid](@ref) 
with [physics\_type](@ref) set to [voltage\_angle\_physics](@ref grid_physics_list). The voltage angle at a certain node 
can also be constrained through the parameters [voltage\_angle\_max](@ref) and [voltage\_angle\_min](@ref). More details 
on the use of lossless nodal DC power flows are described [here](@ref Lossless-nodal-DC-power-flows).

To enable pressure driven gas network calculations, all [node](@ref)s must be related to a [grid](@ref) with 
[physics\_type](@ref) set to [pressure\_physics](@ref grid_physics_list), in order to trigger the generation of the 
[node\_pressure](@ref) variable. The pressure at a certain node can also be constrainted through the parameters 
[pressure\_max](@ref) and [pressure\_min](@ref). More details on the use of pressure driven gas transfer
are described [here](@ref pressure-driven-gas-transfer).
