# Objective function

The objective function of SpineOpt corresponds to the minimization function of all associate cost-terms.

```math
\begin{aligned}
& \min obj = fuel\_costs + variable\_om\_costs + fixed\_om\_costs + taxes \\
& + operation\_costs + investment\_costs + start\_up\_costs + shut\_down\_costs \\
& + connection\_flow\_costs + renewable\_curtailment\_costs + ramp\_costs
objective\_penalties\\
\end{aligned}
```
TODO: find more precise terminology for objectivepenalties
TODO: add reserve procurement costs

# Fuel costs
For all tuples of (unit,{node,node\_group},direction) for which the parameter [fuel\_cost](@ref) is defined, ther following cost term is added to the objective function.

```math
\begin{aligned}
& fuel\_costs \\
& = \sum_{\substack{(u,n,d,s,t) \in ind(unit_{flow}): \\ (u,n,d) \in (u,ng,d) \\ (u,ng,d) \in ind(fuel\_cost)}}
 unit_{flow}(u,n,d,s,t) \cdot fuel_cost(u,ng,d,t)\\
\end{aligned}
```

# Variable operation and maintanance costs
The costs term `variable_om_costs` is part of the objective function if the parameter [vom\_cost](@ref) is defined.
```math
\begin{aligned}
& vom\_costs \\
& = \sum_{\substack{(u,n,d,s,t) \in ind(unit_{flow}): \\ (u,n,d) \in (u,ng,d) \\ (u,ng,d) \in ind(vom\_cost)}}
 unit_{flow}(u,n,d,s,t) \cdot vom_cost(u,ng,d,t)\\
\end{aligned}
```

# Start up costs
The costs associated with the start-up of a unit are incorporated in the [start\_up\_cost](@ref) parameter. For all units starting up, the following cost term is 
added to `obj`.

```math
\begin{aligned}
& start\_up\_costs \\
& = \sum_{\substack{(u,s,t) \in ind(unit_{started\_up}): \\ u \in ind(start\_up\_cost)}}
 unit_{started\_up}(u,s,t) \cdot start\_up\_cost(u,s,t)\\
\end{aligned}
```

# ...