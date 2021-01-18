The [weight\_relative\_to\_parents](@ref) parameter defines how much weight the [stochastic\_scenario](@ref) gets
in the [Objective function](@ref).
As a [stochastic\_structure\_\_stochastic\_scenario](@ref) relationship parameter, different 
[stochastic\_structure](@ref)s can use different weights for the same [stochastic\_scenario](@ref).
Note that every [stochastic\_scenario](@ref) that appears in the [model](@ref) must have a
[weight\_relative\_to\_parents](@ref) defined for it related to the used [stochastic\_structure](@ref)!
See the [Stochastic Framework](@ref) section for more information about how different [stochastic\_structure](@ref)s
interact in *SpineOpt.jl*.)

Since the [Stochastic Framework](@ref) in *SpineOpt.jl* supports *stochastic directed acyclic graphs* instead of simple
*stochastic trees*, it is possible to define [stochastic\_structure](@ref)s with converging
[stochastic\_scenario](@ref)s.
In these cases, the child [stochastic\_scenario](@ref)s inherint the weight of all of their parents, and the final
weight that will appear in the [Objective function](@ref) is calculated as shown below:

```
# For root `stochastic_scenarios` (meaning no parents)

weight(scenario) = weight_relative_to_parents(scenario)

# If not a root `stochastic_scenario`

weight(scenario) = sum([weight(parent) * weight_relative_to_parents(scenario)] for parent in parents)
```

The above calculation is performed starting from the roots, generation by generation,
until the leaves of the *stochastic DAG*.
Thus, the final weight of each [stochastic\_scenario](@ref) is dependent on the [weight\_relative\_to\_parents](@ref)
[Parameters](@ref) of all its ancestors.