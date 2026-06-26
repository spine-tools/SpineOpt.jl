The parameter [capacity\_margin\_min](@ref) triggers the creation of a [capacity\_margin\_min](@ref) constraint which ensures
that the difference between available unit capacity and demand at the corresponding node is at least
[capacity\_margin\_min](@ref). In [`SpineOpt.add_expression_capacity_margin!`](@ref), storage units' actual flows are used
in place of the capacity. Defining a [capacity\_margin\_min](@ref) can be useful for scheduling unit
maintenance outages (see [outage\_scheduled\_duration](@ref) for how to define a [unit](@ref) outage requirement)
and for triggering unit investments due to capacity shortage. The [capacity\_margin\_min](@ref) constraint can be 
softened by defining [capacity\_margin\_penalty](@ref) this allows violation of the constraint
which are penalised in the objective function.