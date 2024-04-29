The parameter `min_capacity_margin` triggers the creation of a constraint of the same name which ensures
that the difference between available unit capacity and demand at the corresponding node is at least
`min_capacity_margin`. In the calculation of `capacity_margin`, storage units' actual flows are used
in place of the capacity. Defining a `min_capacity_margin` can be useful for scheduling unit
maintenance outages (see [scheduled\_outage\_duration](@ref) for how to define a `unit` outage requirement)
and for triggering unit investments due to capacity shortage. The `min_capacity_margin` constraint can be 
softened by defining [min\_capacity\_margin\_penalty](@ref) this allows violation of the constraint
which are penalised in the objective function.