The `min_capacity_margin_penalty` parameter triggers the addition of the `min_capacity_margin_slack` slack variable
in the `min_capacity_margin` constraint. This allows violation of the constraint which are penalised in the objective function.
This can be used to capture the `capacity_value` of investments. This can also be used to disincentivise scheduling
of maintenance outages during times of low capacity. See [scheduled\_outage\_duration](@ref) for how to define a `unit` 
scheduled outage requirement