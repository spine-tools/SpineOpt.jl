Things that need revising in the documentation

-	Could we maybe some examples of operating costs (I don’t really know what can be added other than fuel and VOM costs). Or is this meant to be used for emission costs for instance?

- Also for the objective penalties some examples could be nice.

-	I think we need to explain a bit better the structure of the renewable curtailment cost? I assume the first term in the subtraction reflects the installed capacity times the capacity factor at a particular timestep, but I am not sure. Also what is the meaning of and t_short t_long here?



# Objective function

The objective function of SpineOpt expresses the minimization of the total system costs associated with maintaining and operating the considered energy system.

```math
\begin{aligned}
& \min obj = v_{unit\_investment\_costs} + v_{connection\_investment\_costs} + v_{storage\_investment\_costs}\\
& + v_{fixed\_om\_costs} + v_{variable\_om\_costs} + v_{fuel\_costs} + v_{operation\_costs} +  v_{start\_up\_costs} \\
& + v_{shut\_down\_costs} + v_{ramp\_costs} + v_{res\_proc\_costs} + v_{res\_start\_up\_costs}\\
& + v_{renewable\_curtailment\_costs} + v_{connection\_flow\_costs} +  v_{taxes} +
v_{objective\_penalties}\\
\end{aligned}
```
Note that each cost term is reflected here as a separate variable that can be expressed mathematically by the equations below. All cost terms are weighted by the associated scenario and temporal block weights. To enhance readability and avoid writing a product of weights in every cost term, all weights are combined in a single weight parameter p_{weight}(). As such, the indices associated with each weight parameter indicate which weights are included.

# Unit investment costs

To take into account unit investments in the objective function, the parameter [unit\_investment\_cost](@ref) can be defined. For all tuples of (unit, scenario, timestep) in the set [units\_invested\_available\_indices](@ref Sets) for which this parameter is defined, an investment cost term is added to the objective function if a unit is invested in during the current optimization window. The total unit investment costs can be expressed as:

```math
\begin{aligned}
& v_{unit\_investment\_costs} \\
& = \sum_{\substack{(u,s,t) \in units\_invested\_available\_indices:\\
      u \in ind(p_{unit\_investment\_cost})}}
    v_{units\_invested}(u, s, t) \cdot p_{unit\_investment\_cost}(u,s,t) \cdot p_{weight}(u,s,t)\\
\end{aligned}
```


# Connection investment costs

To take into account connection investments in the objective function, the parameter [connection\_investment\_cost](@ref) can be defined. For all tuples of (connection, scenario, timestep) in the set [connections\_invested\_available\_indices](@ref Sets) for which this parameter is defined, an investment cost term is added to the objective function if a connection is invested in during the current optimization window. The total connection investment costs can be expressed as:

```math
\begin{aligned}
& v_{connection\_investment\_costs} \\
& = \sum_{\substack{(conn,s,t) \in connections\_invested\_available\_indices: \\ conn \in ind(p_{connection\_investment\_cost})}}
 v_{connections\_invested}(conn, s, t) \cdot p_{connection\_investment\_cost}(conn,s,t) \cdot p_{weight}(conn,s,t) \\
\end{aligned}
```

# Storage investment costs

To take into account connection investments in the objective function, the parameter [storage\_investment\_cost](@ref) can be defined. For all tuples of (node, scenario, timestep) in the set [storages\_invested\_available\_indices](@ref Sets) for which this parameter is defined, an investment cost term is added to the objective function if a node storage is invested in during the current optimization window. The total storage investment costs can be expressed as:

```math
\begin{aligned}
& v_{storage\_investment\_costs} \\
& = \sum_{\substack{(n,s,t) \in storages\_invested\_available\_indices:\\ n \in ind(p_{storage\_investment\_cost})}}
 v_{storages\_invested}(n, s, t) \cdot p_{storage\_investment\_cost}(n,s,t) \cdot p_{weight}(n,s,t) \\
\end{aligned}
```


# Fixed O&M costs

Fixed operation and maintenance costs associated with a specific unit can be accounted for by defining the parameters [fom\_cost](@ref) and [unit\_capacity](@ref). For all tuples of (unit, {node,node\_group}, direction) for which these parameters are defined, and for which tuples (unit, scenario, timestep) exist in the set [units\_on\_indices](@ref Sets), a fixed O&M cost term is added to the objective function. Note that, as the [units\_on\_indices](@ref Sets) are used to retrieve the relevant time slices, the unit of the [fom\_cost](@ref) parameter should per given per resolution of the [units\_on](@ref Variables).
The total fixed O&M costs can be expressed as:

```math
\begin{aligned}
& v_{fixed\_om\_costs} \\
& = \sum_{\substack{(u,n,d) \in ind(p_{unit\_capacity}):\\ u \in ind(p_{fom\_cost})}}
\sum_{\substack{(u,s,t)  \in  units\_on\_indices}}
 p_{unit\_capacity}(u,n,d,s,t) \cdot p_{number\_of\_units}(u,s,t)\cdot
 p_{fom\_cost}(u,s,t)\cdot p_{weight}(t) \cdot
 p_{duration}(t)\\
\end{aligned}
```

# Variable O&M costs

Variable operation and maintenance costs associated with a specific unit can be accounted for by defining the parameter ([vom\_cost](@ref)). For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set [unit\_flow\_indices](@ref Sets) for which this parameter is defined, a variable O&M cost term is added to the objective function. As the parameter [vom\_cost](@ref) is a dynamic parameter, the cost term is multiplied with the duration of each timestep.
The total variable O&M costs can be expressed as:

```math
\begin{aligned}
& v_{variable\_om\_costs} \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices: \\(u,n,d) \in ind(p_{vom\_cost})}}
 v_{unit\_flow}(u, n, d, s, t) \cdot  p_{vom\_cost}(u,n,d,s,t) \cdot p_{weight}(n,s,t) \cdot p_{duration}(t)\\
\end{aligned}
```

# Fuel costs
Fuel costs associated with a specific unit can be accounted for by defining the parameter [fuel\_cost](@ref). For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set [unit\_flow\_indices](@ref Sets) for which this parameter is defined, a fuel cost term is added to the objective function. As the parameter [fuel\_cost](@ref) is a dynamic parameter, the cost term is multiplied with the duration of each timestep. The total fuel costs can be expressed as:

```math
\begin{aligned}
& v_{fuel\_costs} \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ (u,n,d) \in ind(p_{fuel\_cost})}}
 v_{unit\_flow}(u, n, d, s, t) \cdot  p_{fuel\_cost}(u,n,d,s,t) \cdot p_{weight}(n,s,t) \cdot p_{duration}(t)\\
\end{aligned}
```

# Operating costs
To account for other operating costs associated with a specific unit, the [operating\_cost](@ref) parameter can be defined. For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set [unit\_flow\_indices](@ref Sets) for which this parameter is defined, an operating cost term is added to the objective function.
As the parameter [operating\_cost](@ref) is a dynamic parameter, the cost term is multiplied with the duration of each timestep.
The total operating costs can be expressed as:

```math
\begin{aligned}
& v_{operating\_costs} \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices: \\ (u,n,d) \in ind(p_{operating\_cost})}}
 v_{unit\_flow}(u, n, d, s, t) \cdot  p_{operating\_cost}(u,n,d,s,t) \cdot p_{weight}(n,s,t) \cdot p_{duration}(t)\\
\end{aligned}
```

# Connection flow costs
To account for operational costs associated with flows over a specific connection, the [connection\_flow\_cost](@ref) parameter can be defined. For all tuples of (conn, {node,node\_group}, direction, scenario, timestep) in the set [connection\_flow\_indices](@ref Sets) for which this parameter is defined, a connection flow cost term is added to the objective function. The total connection flow costs can be expressed as:

```math
\begin{aligned}
& v_{connection\_flow\_costs} \\
& = \sum_{\substack{(conn,n,d,s,t) \in connection\_flow\_indices: \\ conn \in ind(p_{connection\_flow\_cost})}}
v_{connection\_flow }(conn, n, d, s, t) \cdot  p_{connection\_flow\_cost}(conn,s,t) \cdot p_{weight}(n,s,t) \cdot p_{duration}(t)\\
\end{aligned}
```


# Start up costs
Start up costs associated with a specific unit can be included by defining the [start\_up\_cost](@ref) parameter. For all tuples of (unit, scenario, timestep) in the set [units\_on\_indices](@ref Sets) for which this parameter is defined, a start up cost term is added to the objective function. The total start up costs can be expressed as:

```math
\begin{aligned}
& v_{start\_up\_costs} \\
& = \sum_{\substack{(u,s,t) \in units\_on\_indices:\\ u \in ind(p_{start\_up\_cost})}}
 v_{units\_started\_up}(u, s, t) \cdot p_{start\_up\_cost}(u,s,t)\cdot p_{weight}(u,s,t)\\
\end{aligned}
```
# Shut down costs
Shut down costs associated with a specific unit can be included by defining the [shut\_down\_cost](@ref) parameter. For all tuples of (unit, scenario, timestep) in the set [units\_on\_indices](@ref Sets) for which this parameter is defined, a shut down cost term is added to the objective function. The total shut down costs can be expressed as:

```math
\begin{aligned}
& v_{shut\_down\_costs} \\
& = \sum_{\substack{(u,s,t) \in units\_on\_indices:\\ u \in ind(p_{shut\_down\_cost})}}
v_{units\_shut\_down}(u,s,t) \cdot p_{start\_up\_cost}(u,s,t)\cdot p_{weight}(u,s,t)\\
\end{aligned}
```

# Ramping costs
To account for the ramping costs (up and down) associated with a specific unit, the parameters [ramp\_up\_cost](@ref) and [ramp\_down\_cost](@ref) can be defined. For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the sets [ramp\_up\_unit\_flow\_indices](@ref Sets) and [ramp\_down\_unit\_flow\_indices](@ref Sets) for which [ramp\_up\_cost](@ref), respectively [ramp\_down\_cost](@ref) is  defined, a ramping cost term is added to the objective function. The total ramping costs can be expressed as:

```math
\begin{aligned}
& v_{ramp\_costs} \\
& = \sum_{\substack{(u,n,d,s,t) \in ramp\_up\_unit\_flow\_indices: \\ (u,n,d) \in ind(p_{ramp\_up\_cost})}}
v_{ramp\_up\_unit\_flow}(u, n, d, s, t)\cdot p_{ramp\_up\_cost}(u,n,d,s,t)\cdot p_{weight}(n,s,t)\cdot p_{duration}(t)\\
 & + \sum_{\substack{(u,n,d,s,t) \in ramp\_down\_unit\_flow\_indices: \\ (u,n,d) \in ind(p_{ramp\_down\_cost})}}
  v_{ramp\_down\_unit\_flow}(u, n, d, s, t) \cdot p_{ramp\_down\_cost}(u,n,d,s,t)\cdot p_{weight}(n,s,t) \cdot p_{duration}(t)\\
\end{aligned}
```


# Reserve procurement costs
The procurement costs for reserves provided by a specific unit can be accounted for by defining the [reserve\_procurement\_cost](@ref) parameter. For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set [unit\_flow\_indices](@ref Sets) for which this parameter is defined, a reserve procurement cost term is added to the objective function. The total reserve procurement costs can be expressed as:

```math
\begin{aligned}
& v_{res\_proc\_costs} \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices: \\ (u,n,d) \in ind(p_{reserve\_procurement\_cost})}}
v_{unit\_flow}(u, n, d, s, t) \cdot p_{reserve\_procurement\_cost}(u,n,d,s,t) \cdot p_{weight}(n,s,t) \cdot p_{duration}(t)\\
\end{aligned}
```


# Reserve start up costs
The start up costs for reserves provided by a specific unit can be accounted for by defining the [res\_start\_up\_cost](@ref) parameter. For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set [nonspin\_units\_started\_up\_indices](@ref Sets) for which this parameter is defined, a reserve start up cost term is added to the objective function. The total reserve start up costs can be expressed as:

```math
\begin{aligned}
& v_{res\_start\_up\_costs} \\
& = \sum_{\substack{(u,n,s,t) \in nonspin\_units\_started\_up\_indices: \\ (u,n,d) \in ind(p_{res\_start\_up\_cost) }}}
v_{nonspin\_units\_started\_up}(u, n, s, t) \cdot p_{res\_start\_up\_cost}(u,n,d,s,t)\cdot p_{weight}(u,s,t)\\
\end{aligned}
```

# Renewable curtailment costs
The curtailment costs of renewable units can be accounted for by defining the parameters [curtailment\_cost](@ref) and [unit\_capacity](@ref). For all tuples of (unit,  {node,node\_group}, direction) for which these parameters are defined, and for which tuples (unit, scenario, timestep\_long) exist in the set [units\_on\_indices](@ref Sets), and for which tuples (unit, {node,node\_group}, direction, scenario, timestep\_short) exist in the set [unit\_flow\_indices](@ref Sets), a renewable curtailment cost term is added to the objective function. The total renewable curtailment costs can be expressed as:

```math
\begin{aligned}
& v_{renewable\_curtailment\_costs} \\
& = \sum_{\substack{(u,n,d) \in ind(p_{unit\_capacity}): \\ u \in ind(p_{curtailment\_cost})}}
\sum_{\substack{(u,s,t_{long}) \in units\_on\_indices}}
\sum_{\substack{(u,n,s,t_{short}) \in unit\_flow\_indices}}


  p_{curtailment\_cost}(u,s,t_{short})\cdot\left[  v_{units\_available}(u, s, t_{long})\cdot p_{unit\_capacity}(u,n,d,s,t_{short}) \cdot  p_{unit\_conv\_cap\_to\_flow}(u,n,d,s,t_{short}) - v_{unit\_flow}(u, n, d, s, t_{short})  \right] \cdot p_{weight}(n,s,t_{short}) \cdot p_{duration}(t_{short})\\
\end{aligned}
```

# Taxes
To account for taxes on certain commodity flows, the tax unit flow parameters (i.e., [tax\_net\_unit\_flow](@ref), [tax\_out\_unit\_flow](@ref) and [tax\_in\_unit\_flow](@ref)) can be defined. For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set [unit\_flow\_indices](@ref Sets) for which these parameters are defined, a tax term is added to the objective function. The total taxes can be expressed as:

```math
\begin{aligned}
& v_{taxes} \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ n \in ind(p_{tax\_net\_unit\_flow}) \& d=  to\_node}}
v_{unit\_flow}(u, n, d, s, t)\cdot p_{tax\_net\_unit\_flow}(n,s,t)\cdot p_{weight}(n,s,t) \cdot p_{duration}(t)\\
& - \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ n \in ind(p_{tax\_net\_unit\_flow}) \& d=  from\_node}}
v_{unit\_flow}(u, n, d, s, t)\cdot p_{tax\_net\_unit\_flow}(n,s,t)\cdot p_{weight}(n,s,t)\cdot p_{duration}(t)\\
 & + \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ n \in ind(p_{tax\_out\_unit\_flow}) \& d=  from\_node}}
 v_{unit\_flow}(u, n, d, s, t)\cdot p_{tax\_out\_unit\_flow}(n,s,t)\cdot p_{weight}(n,s,t) \cdot p_{duration}(t)\\
 & + \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ n \in ind(p_{tax\_in\_unit\_flow}) \& d=  to\_node}}
 v_{unit\_flow}(u, n, d, s, t)\cdot p_{tax\_in\_unit\_flow}(n,s,t)\cdot p_{weight}(n,s,t) \cdot p_{duration}(t)\\
\end{aligned}
```


# Objective penalties
Penalty cost terms associated with the slack variables of a specific constraint can be accounted for by defining a [node\_slack\_penalty](@ref) parameter. For all tuples of ({node,node\_group}, scenario, timestep) in the set [node\_slack\_indices](@ref Sets) for which this parameter is defined, a penalty term is added to the objective function. The total objective penalties can be expressed as:

```math
\begin{aligned}
& v_{objective\_penalties} \\
& = \sum_{\substack{(u,s,t) \in node\_slack\_indices}}
\left[v_{node\_slack\_neg}(n, s, t)-v_{node\_slack\_pos}(n, s, t) \right]\cdot p_{node\_slack\_penalty}(n,s,t)\cdot p_{weight}(n,s,t) \cdot p_{duration}(t)\\
\end{aligned}
```
