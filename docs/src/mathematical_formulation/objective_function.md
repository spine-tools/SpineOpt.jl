# Objective function

The objective function of SpineOpt expresses the minimization of the total system costs associated with maintaining and operating the considered energy system.

```math
\begin{aligned}
& \min obj = unit\_investment\_costs + connection\_investment\_costs + storage\_investment\_costs\\
& + fixed\_om\_costs + variable\_om\_costs + fuel\_costs + operation\_costs +  start\_up\_costs \\
& + shut\_down\_costs + ramp\_costs + res\_proc\_costs + res\_start\_up\_costs\\
& + renewable\_curtailment\_costs + connection\_flow\_costs +  taxes +
objective\_penalties\\
\end{aligned}
```


# Unit investment costs

For all tuples of (unit, scenario, timestep) in the set units\_invested\_available\_indices, an investment cost term is added to the objective function. The total unit investment costs can be expressed as:

```math
\begin{aligned}
& unit\_investment\_costs \\
& = \sum_{\substack{(u,s,t) \in units\_invested\_available\_indices}}
    v_{units\_invested}(u, s, t) \cdot unit\_investment\_cost(u,s,t) \cdot W^{TB}_t \cdot W^{SS}_s\\
\end{aligned}
```


# Connection investment costs

For all tuples of (connection, scenario, timestep) in the set connections\_invested\_available\_indices, an investment cost term is added to the objective function. The total connection investment costs can be expressed as:

```math
\begin{aligned}
& connection\_investment\_costs \\
& = \sum_{\substack{(conn,s,t) \in connections\_invested\_available\_indices}}
 v_{connections\_invested}(conn, s, t) \cdot connection\_investment\_cost(conn,s,t)\cdot W^{TB}_t \cdot W^{SS}_s\\
\end{aligned}
```

# Storage investment costs

For all tuples of (node, scenario, timestep) in the set storages\_invested\_available\_indices, an investment cost term is added to the objective function. The total storage investment costs can be expressed as:

```math
\begin{aligned}
& storage\_investment\_costs \\
& = \sum_{\substack{(n,s,t) \in storages\_invested\_available\_indices}}
 v_{storages\_invested}(n, s, t) \cdot storage\_investment\_cost(n,s,t)\cdot W^{TB}_t \cdot W^{SS}_s\\
\end{aligned}
```


# Fixed O&M costs

For all tuples of (unit, scenario, timestep) for which the parameter [fom\_cost](@ref) is defined, a fixed O&M cost term is added to the objective function. The total fixed O&M costs can be expressed as:

```math
\begin{aligned}
& fixed\_om\_costs \\
& = \sum_{\substack{(u,s,t) \in units\_on\_indices}}
 unit\_capacity(u,n,d, s, t) \cdot number\_of\_units(u,s,t)\cdot fom\_cost(u,s,t)\\
\end{aligned}
```
# Variable O&M costs

For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) for which the parameter [vom\_cost](@ref) is defined, a variable O&M cost term is added to the objective function. The total variable O&M costs can be expressed as:

```math
\begin{aligned}
& variable\_om\_costs \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices}}
 v_{unit\_flow}(u, n, d, s, t) \cdot  vom\_cost(u,n,d,s,t) \cdot \left(duration+weights\right)\\
\end{aligned}
```

# Fuel costs
For all tuples of (unit,{node,node\_group},direction, scenario, timestep) for which the parameter [fuel\_cost](@ref) is defined, a fuel cost term is added to the objective function. The total fuel costs can be expressed as:

```math
\begin{aligned}
& fuel\_costs \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices}}
 v_{unit\_flow}(u, n, d, s, t) \cdot  fuel\_cost(u,n,d,s,t) \cdot \left(duration+weights\right)\\
\end{aligned}
```

# Operating costs
For all tuples of (unit,{node,node\_group},direction, scenario, timestep) for which the parameter [operating\_cost](@ref) is defined, an operating cost term is added to the objective function. The total operating costs can be expressed as:

```math
\begin{aligned}
& operating\_costs \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices}}
 v_{unit\_flow}(u, n, d, s, t) \cdot  operating\_cost(u,n,d,s,t) \cdot \left(duration+weights\right)\\
\end{aligned}
```


# Start up costs
For all tuples of (unit, scenario, timestep) for which the parameter [start\_up\_cost](@ref) is defined, a start up cost term is added to the objective function. The total start up costs can be expressed as:

```math
\begin{aligned}
& start\_up\_costs \\
& = \sum_{\substack{(u,s,t) \in units\_on\_indices}}
 v_{units\_started\_up}(u, s, t) \cdot start\_up\_cost(u,s,t)\cdot \left(weights\right)\\
\end{aligned}
```
# Shut down costs
For all tuples of (unit, scenario, timestep) for which the parameter [shut\_down\_cost](@ref) is defined, a shut down cost term is added to the objective function. The total shut down costs can be expressed as:

```math
\begin{aligned}
& shut\_down\_costs \\
& = \sum_{\substack{(u,s,t) \in units\_on\_indices}}
v_{units\_shut\_down}(u,s,t) \cdot start\_up\_cost(u,s,t)\cdot \left(weights\right)\\
\end{aligned}
```

# Ramping costs
For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) for which the parameters [ramp\_up\_cost](@ref) or [ramp\_down\_cost](@ref) are defined, a ramping cost term is added to the objective function. The total ramping costs can be expressed as:

```math
\begin{aligned}
& ramp\_costs \\
& = \sum_{\substack{(u,n,d,s,t) \in ramp\_up\_unit\_flow\_indices}}
v_{ramp\_up\_unit\_flow}(u, n, d, s, t)\cdot ramp\_up\_cost(u,n,d,s,t)\cdot \left(weights\right)\\
 & + \sum_{\substack{(u,n,d,s,t) \in ramp\_down\_unit\_flow\_indices}}
  v_{ramp\_down\_unit\_flow}(u, n, d, s, t) \cdot ramp\_up\_cost(u,n,d,s,t)\cdot \left(weights\right)\\
\end{aligned}
```


# Reserve procurement costs
For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) for which the parameter [reserve\_procurement\_cost](@ref) is defined, a reserve procurement cost term is added to the objective function. The total resereve procurement costs can be expressed as:

```math
\begin{aligned}
& res\_proc\_costs \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices}}
v_{unit\_flow}(u, n, d, s, t) \cdot reserve\_procurement\_cost(u,n,d,s,t)\cdot \left(weights\right)\\
\end{aligned}
```


# Reserve start up costs
For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) for which the parameter [res\_start\_up\_cost](@ref) is defined, a reserve start up cost term is added to the objective function. The total reserve start up costs can be expressed as:

```math
\begin{aligned}
& res\_start\_up\_costs \\
& = \sum_{\substack{(u,n,s,t) \in nonspin\_units\_started\_up\_indices}}
v_{nonspin\_units\_started\_up}(u, n, s, t) \cdot res\_start\_up\_cost(u,n,d,s,t)\cdot \left(weights\right)\\
\end{aligned}
```

# Renewable curtailment costs
For all tuples of (unit,  scenario, timestep) for which the parameter [curtailment\_cost](@ref) is defined, a renewable curtailment cost term is added to the objective function. The total renewable curtailment costs can be expressed as:

```math
\begin{aligned}
& renewable\_curtailment\_costs \\
& = \sum_{\substack{(u,n,s,t_{short}) \in unit\_flow\_indices:\\ (u,s,t_{long}) \in units\_on\_indices}}


  curtailment\_cost(u,s,t)\cdot\left[  v_{units\_available}(u, s, t)\cdot unit\_capacity \cdot  unit\_conv\_cap\_to\_flow - v_{unit\_flow}(u, n, d, s, t_{short})  \right] \cdot\left(weights\right)\\
\end{aligned}
```

# Connection flow costs
For all tuples of (conn, scenario, timestep) for which the parameter [connection\_flow\_cost](@ref) is defined, a connection flow cost term is added to the objective function. The total connection flow costs can be expressed as:

```math
\begin{aligned}
& connection\_flow\_costs \\
& = \sum_{\substack{(conn,n,d,s,t) \in connection\_flow\_indices}}
v_{connection\_flow }(conn, n, d, s, t) \cdot  connection\_flow\_cost(conn,s,t) \cdot \left(duration+weights\right)\\
\end{aligned}
```


# Taxes
For all tuples of ({node,node\_group}, scenario, timestep) for which the parameters [tax\_net\_unit\_flow](@ref), [tax\_out\_unit\_flow](@ref) or [tax\_in\_unit\_flow](@ref) are defined, a tax term is added to the objective function. The total taxes can be expressed as:

```math
\begin{aligned}
& taxes \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ d=  to\_node}}
v_{unit\_flow}(u, n, d, s, t)\cdot tax\_net\_unit\_flow(n,s,t)\cdot \left(weights\right)\\
& - \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ d=  from\_node}}
v_{unit\_flow}(u, n, d, s, t)\cdot tax\_net\_unit\_flow(n,s,t)\cdot \left(weights\right)\\
 & + \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices}}
 v_{unit\_flow}(u, n, d, s, t)\cdot tax\_out\_unit\_flow(n,s,t)\cdot \left(weights\right)\\
 & + \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices}}
 v_{unit\_flow}(u, n, d, s, t)\cdot tax\_in\_unit\_flow(n,s,t)\cdot \left(weights\right)\\
\end{aligned}
```

# Objective penalties
For all tuples of ({node,node\_group}, scenario, timestep) for which the parameter [node\_slack\_penalty](@ref) is defined, a penalty term is added to the objective function. The total objective penalties can be expressed as:

```math
\begin{aligned}
& objective\_penalties \\
& = \sum_{\substack{(u,s,t) \in node\_slack\_indices}}
\left(v_{node\_slack\_neg}(n, s, t)-v_{node\_slack\_pos}(n, s, t) \right)\cdot node\_slack\_penalty(n,s,t)\cdot \left(weights\right)\\
\end{aligned}
```
