The [max\_units\_on\_coefficient\_out\_out](@ref) parameter is an optinal coefficient in the
[unit output-output ratio constraint](@ref ratio_out_out) controlled by the [max\_ratio\_out\_out\_unit\_flow](@ref) parameter.
Essentially, it acts as a coefficient for the `units_on` [variable](@ref Variables) in the constraint,
allowing for making the maximum conversion ratio dependent on the amount of online capacity.

Note that there are different parameters depending on the directions of the `unit_flow` [variables](@ref Variables)
being constrained: [max\_units\_on\_coefficient\_in\_in](@ref), [max\_units\_on\_coefficient\_out\_in](@ref), and
[max\_units\_on\_coefficient\_in\_out](@ref), all of which apply to their respective [constraints](@ref constraint_ratio_unit_flow).
Similarly, there are different parameters for setting minimum or fixed conversion rates, e.g. 
[min\_units\_on\_coefficient\_out\_out](@ref) and [fix\_units\_on\_coefficient\_out\_out](@ref).