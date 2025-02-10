The parameter `capacity_margin_min` triggers the creation of a `min_capacity_margin` constraint which ensures
that the difference between available unit capacity and demand at the corresponding node is at least
`capacity_margin_min`. In the calculation of `capacity_margin`, storage units' actual flows are used
in place of the capacity. Defining a `capacity_margin_min` can be useful for scheduling unit
maintenance outages (see [outage\_scheduled\_duration](@ref) for how to define a `unit` outage requirement)
and for triggering unit investments due to capacity shortage. The `min_capacity_margin` constraint can be 
softened by defining [min\_capacity\_margin\_penalty](@ref) this allows violation of the constraint
which are penalised in the objective function.