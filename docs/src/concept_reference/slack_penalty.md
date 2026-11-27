!!! warning
    EXPERIMENTAL!

The penalty for deviating from an [output](@ref) value that a [stage](@ref) fixes in its child models, see [Multi-stage optimisation](@ref).

Without [slack\_penalty](@ref), the [output](@ref) is fixed exactly to the value from the [stage](@ref). With it, the child model can deviate from the value, and each unit of deviation, up or down, adds the penalty to the objective function. This can be used e.g. when the stage and the child model don't match exactly and fixing the value exactly would make the child model infeasible.

[slack\_penalty](@ref) is defined for [stage\_\_output\_\_unit](@ref), [stage\_\_output\_\_node](@ref) and [stage\_\_output\_\_connection](@ref).
