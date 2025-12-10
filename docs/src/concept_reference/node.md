The [node](@ref) is perhaps the most important `object class` out of the [Systemic object classes](@ref),
as it is what connects the rest together via the [Systemic relationship classes](@ref).
Essentially, [node](@ref)s act as points in the modelled [grid](@ref)
where commodity balance is enforced via the [node balance](@ref constraint_nodal_balance) and [node injection](@ref constraint_node_injection) constraints,
tying together the inputs and outputs from [unit](@ref)s and [connection](@ref)s,
as well as any external [demand](@ref).
Furthermore, [node](@ref)s play a crucial role for defining the temporal and stochastic structures of the [model](@ref)
via the [node\_\_temporal\_block](@ref) and [node\_\_stochastic\_structure](@ref) relationships.
For more details about the [Temporal Framework](@ref) and the [Stochastic Framework](@ref), please refer to the
dedicated sections.

Since [node](@ref)s act as the points where commodity balance is enforced,
this also makes them a natural fit for implementing *storage*.
The [storage\_activate](@ref) parameter controls whether a [node](@ref) has a `node_state` variable,
which essentially represents the commodity content of the [node](@ref).
The [storage\_state\_coefficient](@ref) parameter tells how the `node_state` variable relates to all the commodity flows.
Storage losses are handled via the [storage\_self\_discharge](@ref) parameter,
and potential diffusion of commodity content to other [node](@ref)s via the [diffusion\_coefficient](@ref) parameter for the
[node\_\_node](@ref) relationship.
