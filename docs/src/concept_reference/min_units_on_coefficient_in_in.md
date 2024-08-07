The [min\_units\_on\_coefficient\_in\_in](@ref) parameter is an optional coefficient in the
[unit input-input ratio constraint](@ref ratio_unit_flow) controlled by the [min\_ratio\_in\_in\_unit\_flow](@ref) parameter.
Essentially, it acts as a coefficient for the [units\_on](@ref) variable in the constraint,
allowing for making the minimum conversion ratio dependent on the amount of online capacity.

Note that there are different parameters depending on the directions of the [unit\_flow](@ref) variables
being constrained: [min\_units\_on\_coefficient\_in\_out](@ref), [min\_units\_on\_coefficient\_out\_in](@ref), and
[min\_units\_on\_coefficient\_out\_out](@ref), all of which apply to their respective [constraints](@ref constraint_ratio_unit_flow).
Similarly, there are different parameters for setting maximum or fixed conversion rates, e.g. 
[max\_units\_on\_coefficient\_in\_in](@ref) and [fix\_units\_on\_coefficient\_in\_in](@ref).