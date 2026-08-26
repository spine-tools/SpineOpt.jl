The [capacity\_margin\_penalty](@ref) parameter triggers the addition of the [min\_capacity\_margin\_slack](@ref var_min_capacity_margin_slack) slack variable
in the [minimum capacity margin](@ref constraint_min_capacity_margin) constraint. This allows violation of the constraint which are penalised in the objective function.
This can be used to capture the *capacity value*  of investments. This can also be used to disincentivise scheduling
of maintenance outages during times of low capacity. See [outage\_scheduled\_duration](@ref) for how to define a [unit](@ref) 
scheduled outage requirement.