The [fix\_units\_on\_coefficient\_out\_in](@ref) parameter is an optional coefficient in the
[unit output-input ratio constraint](@ref ratio_unit_flow) controlled by the [fix\_ratio\_out\_in\_unit\_flow](@ref) parameter.
Essentially, it acts as a coefficient for the [units\_on](@ref) variable in the constraint,
allowing for fixing the conversion ratio depending on the amount of online capacity.

Note that there are different parameters depending on the directions of the [unit\_flow](@ref) variables
being constrained: [fix\_units\_on\_coefficient\_in\_in](@ref), [fix\_units\_on\_coefficient\_in\_out](@ref), and
[fix\_units\_on\_coefficient\_out\_out](@ref), all of which apply to their respective [constraints](@ref constraint_ratio_unit_flow).
Similarly, there are different parameters for setting minimum or maximum conversion rates, e.g. 
[min\_units\_on\_coefficient\_out\_in](@ref) and [max\_units\_on\_coefficient\_out\_in](@ref).