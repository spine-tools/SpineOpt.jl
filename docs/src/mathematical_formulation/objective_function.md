# Objective function

The objective function of SpineOpt expresses the minimization of the total system costs associated with maintaining and operating the considered energy system.

```math
\begin{aligned}
& \min obj = {unit\_investment\_costs} + {connection\_investment\_costs} + {storage\_investment\_costs}\\
& + {fixed\_om\_costs} + {variable\_om\_costs} + {fuel\_costs}  +  {start\_up\_costs} \\
& + {shut\_down\_costs} + {res\_proc\_costs} \\
& + {renewable\_curtailment\_costs} + {connection\_flow\_costs} +  {taxes} +
{objective\_penalties}\\
\end{aligned}
```
Note that each cost term is reflected here as a separate variable that can be expressed mathematically by the equations below. All cost terms are weighted by the associated scenario and temporal block weights. To enhance readability and avoid writing a product of weights in every cost term, all weights are combined in a single weight parameter ``p^{weight}_{(...)}``. As such, the indices associated with each weight parameter indicate which weights are included.

# Unit investment costs

To take into account unit investments in the objective function, the parameter [unit\_investment\_cost](@ref) can be defined. For all tuples of (unit, scenario, timestep) in the set `units_invested_available_indices` for which this parameter is defined, an investment cost term is added to the objective function if a unit is invested in during the current optimization window. The total unit investment costs can be expressed as:

```math
\begin{aligned}
& {unit\_investment\_costs}
 = \sum_{(u,s,t)}
    v^{units\_invested}_{(u, s, t)} \cdot p^{unit\_investment\_cost}_{(u,s,t)} \cdot p^{weight}_{(u,s,t)}\\
\end{aligned}
```


# Connection investment costs

To take into account connection investments in the objective function, the parameter [connection\_investment\_cost](@ref) can be defined. For all tuples of (connection, scenario, timestep) in the set `connections_invested_available_indices` for which this parameter is defined, an investment cost term is added to the objective function if a connection is invested in during the current optimization window. The total connection investment costs can be expressed as:

```math
\begin{aligned}
& {connection\_investment\_costs}
 = \sum_{(conn,s,t)}
 v^{connections\_invested}_{(conn, s, t)} \cdot p^{connection\_investment\_cost}_{(conn,s,t)} \cdot p^{weight}_{(conn,s,t)} \\
\end{aligned}
```

# Storage investment costs

To take into account storage investments in the objective function, the parameter [storage\_investment\_cost](@ref) can be defined. For all tuples of (node, scenario, timestep) in the set `storages_invested_available_indices` for which this parameter is defined, an investment cost term is added to the objective function if a node storage is invested in during the current optimization window. The total storage investment costs can be expressed as:

```math
\begin{aligned}
& {storage\_investment\_costs} 
 = \sum_{(n,s,t)}
 v^{storages\_invested}_{(n, s, t)} \cdot p^{storage\_investment\_cost}_{(n,s,t)} \cdot p^{weight}_{(n,s,t)} \\
\end{aligned}
```


# Fixed O&M costs

Fixed operation and maintenance costs associated with a specific unit can be accounted for by defining the parameters [fom\_cost](@ref) and [unit\_capacity](@ref). For all tuples of (unit, {node,node\_group}, direction) for which these parameters are defined, and for which tuples (unit, scenario, timestep) exist in the set `units_on_indices`, a fixed O&M cost term is added to the objective function. Note that, as the `units_on_indices` are used to retrieve the relevant time slices, the unit of the [fom\_cost](@ref) parameter should be given per resolution of the [units\_on](@ref).
The total fixed O&M costs can be expressed as:

```math
\begin{aligned}
& {fixed\_om\_costs}
 = 
\sum_{(u,n,d,s,t)}
 \left( p^{number\_of\_units}_{(u,s,t)} + v^{units\_invested\_available}_{(u, s, t)} \right)
 \cdot p^{unit\_capacity}_{(u,n,d,s,t)} \cdot p^{fom\_cost}_{(u,s,t)} \cdot p^{weight}_{(n,s,t)} \cdot \Delta t\\
\end{aligned}
```

# Variable O&M costs

Variable operation and maintenance costs associated with a specific unit can be accounted for by defining the parameter ([vom\_cost](@ref)). For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set `unit_flow_indices` for which this parameter is defined, a variable O&M cost term is added to the objective function. As the parameter [vom\_cost](@ref) is a dynamic parameter, the cost term is multiplied with the duration of each timestep.
The total variable O&M costs can be expressed as:

```math
\begin{aligned}
& {variable\_om\_costs}
 = \sum_{(u,n,d,s,t)}
 v^{unit\_flow}_{(u, n, d, s, t)} \cdot  p^{vom\_cost}_{(u,n,d,s,t)} \cdot p^{weight}_{(n,s,t)} \cdot \Delta t\\
\end{aligned}
```

# Fuel costs
Fuel costs associated with a specific unit can be accounted for by defining the parameter [fuel\_cost](@ref). For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set `unit_flow_indices` for which this parameter is defined, a fuel cost term is added to the objective function. As the parameter [fuel\_cost](@ref) is a dynamic parameter, the cost term is multiplied with the duration of each timestep. The total fuel costs can be expressed as:

```math
\begin{aligned}
& {fuel\_costs}
 = \sum_{(u,n,d,s,t)}
 v^{unit\_flow}_{(u, n, d, s, t)} \cdot  p^{fuel\_cost}_{(u,n,d,s,t)} \cdot p^{weight}_{(n,s,t)} \cdot \Delta t\\
\end{aligned}
```

# Connection flow costs
To account for operational costs associated with flows over a specific connection, the [connection\_flow\_cost](@ref) parameter can be defined. For all tuples of (conn, {node,node\_group}, direction, scenario, timestep) in the set `connection_flow_indices` for which this parameter is defined, a connection flow cost term is added to the objective function. The total connection flow costs can be expressed as:

```math
\begin{aligned}
& {connection\_flow\_costs}
 = \sum_{(conn,n,d,s,t)}
v^{connection\_flow }_{(conn, n, d, s, t)} \cdot  p^{connection\_flow\_cost}_{(conn,s,t)} \cdot p^{weight}_{(n,s,t)} \cdot \Delta t\\
\end{aligned}
```


# Start up costs
Start up costs associated with a specific unit can be included by defining the [start\_up\_cost](@ref) parameter. For all tuples of (unit, scenario, timestep) in the set `units_on_indices` for which this parameter is defined, a start up cost term is added to the objective function. The total start up costs can be expressed as:

```math
\begin{aligned}
& {start\_up\_costs}
 = \sum_{(u,s,t)}
 v^{units\_started\_up}_{(u, s, t)} \cdot p^{start\_up\_cost}_{(u,s,t)} \cdot p^{weight}_{(u,s,t)}\\
\end{aligned}
```
# Shut down costs
Shut down costs associated with a specific unit can be included by defining the [shut\_down\_cost](@ref) parameter. For all tuples of (unit, scenario, timestep) in the set `units_on_indices` for which this parameter is defined, a shut down cost term is added to the objective function. The total shut down costs can be expressed as:

```math
\begin{aligned}
& {shut\_down\_costs}
 = \sum_{(u,s,t)}
v^{units\_shut\_down}_{(u,s,t)} \cdot p^{start\_up\_cost}_{(u,s,t)} \cdot p^{weight}_{(u,s,t)}\\
\end{aligned}
```

# Reserve procurement costs
The procurement costs for reserves provided by a specific unit can be accounted for by defining the [reserve\_procurement\_cost](@ref) parameter. For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set `unit_flow_indices` for which this parameter is defined, a reserve procurement cost term is added to the objective function. The total reserve procurement costs can be expressed as:

```math
\begin{aligned}
& {res\_proc\_costs}
 = \sum_{(u,n,d,s,t)}
v^{unit\_flow}_{(u, n, d, s, t)} \cdot p^{reserve\_procurement\_cost}_{(u,n,d,s,t)} \cdot p^{weight}_{(n,s,t)} \cdot \Delta t
\cdot \left[p^{is\_reserve\_node}_{n}\right] \\
\end{aligned}
```
where
```math
[p] \vcentcolon = \begin{cases}
1 & \text{if } p \text{ is true;}\\
0 & \text{otherwise.}
\end{cases}
```

# Renewable curtailment costs
The curtailment costs of renewable units can be accounted for by defining the parameters [curtailment\_cost](@ref) and [unit\_capacity](@ref). For all tuples of (unit,  {node,node\_group}, direction) for which these parameters are defined, and for which tuples (unit, scenario, timestep\_long) exist in the set `units_on_indices`, and for which tuples (unit, {node,node\_group}, direction, scenario, timestep\_short) exist in the set `unit_flow_indices`, a renewable curtailment cost term is added to the objective function. The total renewable curtailment costs can be expressed as:

```math
\begin{aligned}
& {renewable\_curtailment\_costs}
 = \sum_{(u,n,d,s,t)}
 \left(v^{units\_available}_{(u, s, t)} \cdot p^{unit\_capacity}_{(u,n,d,s,t)} \cdot p^{unit\_conv\_cap\_to\_flow}_{(u,n,d,s,t)}
 - v^{unit\_flow}_{(u, n, d, s, t)} \right)
 \cdot p^{curtailment\_cost}_{(u,s,t)} \cdot p^{weight}_{(n,s,t)} \cdot \Delta t\\
\end{aligned}
```

# Taxes
To account for taxes on certain commodity flows, the tax unit flow parameters (i.e., [tax\_net\_unit\_flow](@ref), [tax\_out\_unit\_flow](@ref) and [tax\_in\_unit\_flow](@ref)) can be defined. For all tuples of (unit, {node,node\_group}, direction, scenario, timestep) in the set `unit_flow_indices` for which these parameters are defined, a tax term is added to the objective function. The total taxes can be expressed as:

```math
\begin{aligned}
{taxes} = 
& \sum_{(u,n,s,t) }
v^{unit\_flow}_{(u, n, to\_node, s, t)} \cdot p^{tax\_net\_unit\_flow}_{(n,s,t)} \cdot p^{weight}_{(n,s,t)} \cdot \Delta t\\
& - \sum_{(u,n,s,t)}
v^{unit\_flow}_{(u, n, from\_node, s, t)} \cdot p^{tax\_net\_unit\_flow}_{(n,s,t)} \cdot p^{weight}_{(n,s,t)} \cdot \Delta t\\
& + \sum_{(u,n,s,t)}
v^{unit\_flow}_{(u, n, from\_node, s, t)} \cdot p^{tax\_out\_unit\_flow}_{(n,s,t)} \cdot p^{weight}_{(n,s,t)} \cdot \Delta t\\
& + \sum_{(u,n,s,t)}
v^{unit\_flow}_{(u, n, to\_node, s, t)} \cdot p^{tax\_in\_unit\_flow}_{(n,s,t)} \cdot p^{weight}_{(n,s,t)} \cdot \Delta t\\
\end{aligned}
```


# Objective penalties
Penalty cost terms associated with the slack variables of a specific constraint can be accounted for by defining a [node\_slack\_penalty](@ref) parameter. For all tuples of ({node,node\_group}, scenario, timestep) in the set `node_slack_indices` for which this parameter is defined, a penalty term is added to the objective function. The total objective penalties can be expressed as:

```math
\begin{aligned}
& {objective\_penalties}
 = \sum_{(n,s,t)}
\left(v^{node\_slack\_neg}_{(n, s, t)} - v^{node\_slack\_pos}_{(n, s, t)} \right) \cdot p^{node\_slack\_penalty}_{(n,s,t)}
\cdot p^{weight}_{(n,s,t)} \cdot \Delta t \\
\end{aligned}
```
