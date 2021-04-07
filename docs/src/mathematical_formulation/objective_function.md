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
Note that each cost term is reflected here as a separate variable that can be expressed mathematically by the equations below.

# Unit investment costs

For all tuples of (unit, scenario, timestep) in the set units\_invested\_available\_indices for which the parameter [unit\_investment\_cost](@ref) is defined, an investment cost term is added to the objective function. The total unit investment costs can be expressed as:

```math
\begin{aligned}
& v_{unit\_investment\_costs} \\
& = \sum_{\substack{(u,s,t) \in units\_invested\_available\_indices:\\
      u \in ind(unit\_investment\_cost)}}
    v_{units\_invested}(u, s, t) \cdot unit\_investment\_cost(u,s,t) \cdot weight\_stochastic\_scenario(u,s) \cdot weight\_temporal\_block(t) \\
\end{aligned}
```


# Connection investment costs

For all tuples of (connection, scenario, timestep) in the set connections\_invested\_available\_indices for which the parameter [connection\_investment\_cost](@ref) is defined, an investment cost term is added to the objective function. The total connection investment costs can be expressed as:

```math
\begin{aligned}
& v_{connection\_investment\_costs} \\
& = \sum_{\substack{(conn,s,t) \in connections\_invested\_available\_indices: \\ conn \in ind(connection\_investment\_cost)}}
 v_{connections\_invested}(conn, s, t) \cdot connection\_investment\_cost(conn,s,t) \cdot weight\_stochastic\_scenario(conn,s) \cdot weight\_temporal\_block(t) \\
\end{aligned}
```

# Storage investment costs

For all tuples of (node, scenario, timestep) in the set storages\_invested\_available\_indices for which the parameter [storage\_investment\_cost](@ref) is defined, an investment cost term is added to the objective function. The total storage investment costs can be expressed as:

```math
\begin{aligned}
& v_{storage\_investment\_costs} \\
& = \sum_{\substack{(n,s,t) \in storages\_invested\_available\_indices:\\ n \in ind(storage\_investment\_cost)}}
 v_{storages\_invested}(n, s, t) \cdot storage\_investment\_cost(n,s,t) \cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \\
\end{aligned}
```


# Fixed O&M costs

For all tuples of (unit, {node,node\_group}, direction) for which the parameters [unit\_capacity](@ref) and [fom\_cost](@ref) are defined, and for which tuples (unit, scenario, timestep) exist in the set units\_on\_indices, a fixed O&M cost term is added to the objective function. The total fixed O&M costs can be expressed as:

```math
\begin{aligned}
& v_{fixed\_om\_costs} \\
& = \sum_{\substack{(u,n,d) \in ind(unit\_capacity):\\ u \in ind(fom\_cost)}}
\sum_{\substack{(u,s,t)  \in  units\_on\_indices}}
 unit\_capacity(u,n,d,s,t) \cdot number\_of\_units(u,s,t)\cdot fom\_cost(u,s,t)\cdot weight\_temporal\_block(t) \cdot duration(t)\\
\end{aligned}
```

?Where is the variable in this equation?
# Variable O&M costs

For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set unit\_flow\_indices for which the parameter [vom\_cost](@ref) is defined, a variable O&M cost term is added to the objective function. The total variable O&M costs can be expressed as:

```math
\begin{aligned}
& v_{variable\_om\_costs} \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices: \\(u,n,d) \in ind(vom\_cost)}}
 v_{unit\_flow}(u, n, d, s, t) \cdot  vom\_cost(u,n,d,s,t) \cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
\end{aligned}
```

# Fuel costs
For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set unit\_flow\_indices for which the parameter [fuel\_cost](@ref) is defined, a fuel cost term is added to the objective function. The total fuel costs can be expressed as:

```math
\begin{aligned}
& v_{fuel\_costs} \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ (u,n,d) \in ind(fuel\_cost)}}
 v_{unit\_flow}(u, n, d, s, t) \cdot  fuel\_cost(u,n,d,s,t) \cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
\end{aligned}
```

# Operating costs
For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set unit\_flow\_indices for which the parameter [operating\_cost](@ref) is defined, an operating cost term is added to the objective function. The total operating costs can be expressed as:

```math
\begin{aligned}
& v_{operating\_costs} \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices: \\ (u,n,d) \in ind(operating\_cost)}}
 v_{unit\_flow}(u, n, d, s, t) \cdot  operating\_cost(u,n,d,s,t) \cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
\end{aligned}
```

# Connection flow costs
For all tuples of (conn, {node,node\_group}, direction, scenario, timestep) in the set connection\_flow\_indices for which the parameter [connection\_flow\_cost](@ref) is defined, a connection flow cost term is added to the objective function. The total connection flow costs can be expressed as:

```math
\begin{aligned}
& v_{connection\_flow\_costs} \\
& = \sum_{\substack{(conn,n,d,s,t) \in connection\_flow\_indices: \\ conn \in ind(connection\_flow\_cost)}}
v_{connection\_flow }(conn, n, d, s, t) \cdot  connection\_flow\_cost(conn,s,t) \cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
\end{aligned}
```


# Start up costs
For all tuples of (unit, scenario, timestep) in the set units\_on\_indices for which the parameter [start\_up\_cost](@ref) is defined, a start up cost term is added to the objective function. The total start up costs can be expressed as:

```math
\begin{aligned}
& v_{start\_up\_costs} \\
& = \sum_{\substack{(u,s,t) \in units\_on\_indices:\\ u \in ind(start\_up\_cost)}}
 v_{units\_started\_up}(u, s, t) \cdot start\_up\_cost(u,s,t)\cdot weight\_stochastic\_scenario(u,s) \cdot weight\_temporal\_block(t)\\
\end{aligned}
```
# Shut down costs
For all tuples of (unit, scenario, timestep) in the set units\_on\_indices for which the parameter [shut\_down\_cost](@ref) is defined, a shut down cost term is added to the objective function. The total shut down costs can be expressed as:

```math
\begin{aligned}
& v_{shut\_down\_costs} \\
& = \sum_{\substack{(u,s,t) \in units\_on\_indices:\\ u \in ind(shut\_down\_cost)}}
v_{units\_shut\_down}(u,s,t) \cdot start\_up\_cost(u,s,t)\cdot weight\_stochastic\_scenario(u,s) \cdot weight\_temporal\_block(t)\\
\end{aligned}
```

# Ramping costs
For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the sets ramp\_up\_unit\_flow\_indices and ramp\_down\_unit\_flow\_indices for which the parameter [ramp\_up\_cost](@ref), respectively [ramp\_down\_cost](@ref) is defined, a ramping cost term is added to the objective function. The total ramping costs can be expressed as:

```math
\begin{aligned}
& v_{ramp\_costs} \\
& = \sum_{\substack{(u,n,d,s,t) \in ramp\_up\_unit\_flow\_indices: \\ (u,n,d) \in ind(ramp\_up\_cost)}}
v_{ramp\_up\_unit\_flow}(u, n, d, s, t)\cdot ramp\_up\_cost(u,n,d,s,t)\cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
 & + \sum_{\substack{(u,n,d,s,t) \in ramp\_down\_unit\_flow\_indices: \\ (u,n,d) \in ind(ramp\_down\_cost)}}
  v_{ramp\_down\_unit\_flow}(u, n, d, s, t) \cdot ramp\_up\_cost(u,n,d,s,t)\cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
\end{aligned}
```


# Reserve procurement costs
For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set unit\_flow\_indices for which the parameter [reserve\_procurement\_cost](@ref) is defined, a reserve procurement cost term is added to the objective function. The total reserve procurement costs can be expressed as:

```math
\begin{aligned}
& v_{res\_proc\_costs} \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices: \\ (u,n,d) \in ind(reserve\_procurement\_cost)}}
v_{unit\_flow}(u, n, d, s, t) \cdot reserve\_procurement\_cost(u,n,d,s,t) \cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
\end{aligned}
```


# Reserve start up costs
For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set nonspin\_units\_started\_up\_indices for which the parameter [res\_start\_up\_cost](@ref) is defined, a reserve start up cost term is added to the objective function. The total reserve start up costs can be expressed as:

```math
\begin{aligned}
& v_{res\_start\_up\_costs} \\
& = \sum_{\substack{(u,n,s,t) \in nonspin\_units\_started\_up\_indices: \\ (u,n,d) \in ind(res\_start\_up\_cost) }}
v_{nonspin\_units\_started\_up}(u, n, s, t) \cdot res\_start\_up\_cost(u,n,d,s,t)\cdot weight\_stochastic\_scenario(u,s) \cdot weight\_temporal\_block(t)\\
\end{aligned}
```

# Renewable curtailment costs
For all tuples of (unit,  {node,node\_group}, direction) for which the parameters [unit\_capacity](@ref) and  [curtailment\_cost](@ref) are defined, and for which tuples (unit, scenario, timestep\_long) exist in the set units\_on\_indices, and for which tuples (unit, {node,node\_group}, direction, scenario, timestep\_short) exist in the set unit\_flow\_indices, a renewable curtailment cost term is added to the objective function. The total renewable curtailment costs can be expressed as:

```math
\begin{aligned}
& v_{renewable\_curtailment\_costs} \\
& = \sum_{\substack{(u,n,d) \in ind(unit\_capacity): \\ u \in ind(curtailment\_cost)}}
\sum_{\substack{(u,s,t_{long}) \in units\_on\_indices}}
\sum_{\substack{(u,n,s,t_{short}) \in unit\_flow\_indices}}


  curtailment\_cost(u,s,t_{short})\cdot\left[  v_{units\_available}(u, s, t_{long})\cdot unit\_capacity(u,n,d,s,t_{short}) \cdot  unit\_conv\_cap\_to\_flow(u,n,d,s,t_{short}) - v_{unit\_flow}(u, n, d, s, t_{short})  \right] \cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t_{short}) \cdot duration(t_{short})\\
\end{aligned}
```
? I think this is how it is written in the code, but I am not really sure what the t\_long and t\_short indices actually refer to?


# Taxes
For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set unit\_flow\_indices for which the parameter [tax\_net\_unit\_flow](@ref), [tax\_out\_unit\_flow](@ref) or [tax\_in\_unit\_flow](@ref) is defined, a tax term is added to the objective function. The total taxes can be expressed as:

```math
\begin{aligned}
& v_{taxes} \\
& = \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ n \in ind(tax\_net\_unit\_flow) \& d=  to\_node}}
v_{unit\_flow}(u, n, d, s, t)\cdot tax\_net\_unit\_flow(n,s,t)\cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
& - \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ n \in ind(tax\_net\_unit\_flow) \& d=  from\_node}}
v_{unit\_flow}(u, n, d, s, t)\cdot tax\_net\_unit\_flow(n,s,t)\cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
 & + \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ n \in ind(tax\_out\_unit\_flow) \& d=  from\_node}}
 v_{unit\_flow}(u, n, d, s, t)\cdot tax\_out\_unit\_flow(n,s,t)\cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
 & + \sum_{\substack{(u,n,d,s,t) \in unit\_flow\_indices:\\ n \in ind(tax\_out\_unit\_flow) \& d=  to\_node}}
 v_{unit\_flow}(u, n, d, s, t)\cdot tax\_in\_unit\_flow(n,s,t)\cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
\end{aligned}
```
?Shouldn't the last summation have ind(tax\_in\_unit\_flow) instead of ind(tax\_out\_unit\_flow) ?


# Objective penalties
For all tuples of ({node,node\_group}, scenario, timestep) in the set node\_slack\_indices, a penalty term is added to the objective function. The total objective penalties can be expressed as:

```math
\begin{aligned}
& v_{objective\_penalties} \\
& = \sum_{\substack{(u,s,t) \in node\_slack\_indices}}
\left[v_{node\_slack\_neg}(n, s, t)-v_{node\_slack\_pos}(n, s, t) \right]\cdot node\_slack\_penalty(n,s,t)\cdot weight\_stochastic\_scenario(n,s) \cdot weight\_temporal\_block(t) \cdot duration(t)\\
\end{aligned}
```
