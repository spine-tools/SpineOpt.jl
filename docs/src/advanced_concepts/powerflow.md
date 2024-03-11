# [Power transfer distribution factors (PTDF) based DC power flow](@id ptdf-based-powerflow)
There are two main methodologies for directly including DC powerflow in unit commitment/energy system models. One method is to directly include the bus voltage angles as variables in the model. This method is described in [Nodal lossless DC Powerflow](@ref key-concepts-advanced-nodal-DC).

Here we discuss the method of using power transfer distribution factors (PTDF) for DC power flow and line outage distribution factors (lodf) for security constrained unit commitment.

!!! warning
    The calculations for investments using the PTDF method do not consider the mutual effect of multiple simultaneous investments.
    In other words, the results are (increasingly more) incorrect for (more) lines that interact with each other.
    Yet, this method remains useful for choosing between multiple simultaneous investments that are assumed non-interacting and/or multiple mutually exclusive investments.
    
    On the other hand, investments using the angle based method work for multiple lines but this method is slower and does not take into account the N-1 rule.

!!! warning
    Connecting AC lines through two  DC lines is also not supported in our implementation of the PTDF method but it is possible to do this with our implementation of the angle based method.

## [Key concepts](@id key-concepts-advanced-ptdf-DC)
1. **ptdf**: The power transfer distribution factors are a property of the network reactances and their derivation may be found [here](https://www.worldcat.org/title/power-generation-operation-and-control/oclc/886509477). `ptdf(n, c)` represents the fraction of an injection at [node](@ref) n that will flow on [connection](@ref) c. The flow on [connection](@ref) c is then the sum over all nodes of `ptdf(n, c)*net_injection(c)`. The advantage of this method is that it introduces no additional variables into the problem and instead, introduces only one constraint for each connection whose flow we are interested in monitoring.
2. **lodf**: Line outage distribution factors are a function of the network ptdfs and their derivation is also found [here](https://www.worldcat.org/title/power-generation-operation-and-control/oclc/886509477). `lodf(c_contingency, c_monitored)` represents the fraction of the pre-contingency flow on connection `c_contingency` that will flow on `c_monitored` if `c_contingency` is disconnected. Therefore, the post contingency flow on connection `c_monitored` is the `pre_contingency flow` plus `lodf(c_contingency, c_monitored)\*pre_contingency_flow(c_contingency))`. Therefore, consideration of N contingencies on M monitored lines introduces N x M constraints into the model. Usually one wishes to contain this number and methods are given below to achieve this.
3. **Defining your network** To identify the network for which ptdfs, lodfs and connection_flows will be calculated according to the ptdf method, one does the following:
   - Create [node](@ref) objects for each bus in the model.
   - Create [connection](@ref) objects representing each line of the network: For each connection specify the [connection\_reactance](@ref) parameter and the [connection\_type](@ref) parameter. Setting [connection\_type](@ref)=`connection_type_lossless_bidirectional` simplifies the amount of data that needs to be specified for an eletrical network. See [connection\_type](@ref) for more details   
   - Set the [connection\_\_to\_node](@ref) and [connection\_\_from\_node](@ref) relationships to define the topology of each connection along with the [connection\_capacity](@ref) parameter on one or both of these relationships.
   - Set the [connection\_emergency\_capacity](@ref) parameter to define the post contingency rating if lodf-based N-1 security constraints are to be included
   - Create a [commodity](@ref) object and [node__commodity](@ref) relationships for all the nodes that comprise the electrical network for which PTDFs are to be calculated.
   - Specify the [commodity_physics](@ref) parameter for the commodity to `:commodity_physics_ptdf` if ptdf-based DC load flow is desired with no N-1 security constraints or to `:commodity_physics_lodf` if it is desired to include lodf-based N-1 security constraints
   - To identify the reference bus([node](@ref)) specify the [node\_opf\_type](@ref) parameter for the appropriate [node](@ref) with the value `node_opf_type_reference`.
4. **Controlling problem size**
   - The lines to be monitored are specified by setting the [connection\_monitored](@ref) property for each connection for which a flow constraint is to be generated
   - The contingencies to be considered are specified by setting the [connection\_contingency](@ref) property for the appropriate connections. For N contingencies and M monitored lines, N x M constraints will be generated.
   - If the `lodf(c_contingency, c_monitored)` is very small, it means the outage of `c_contingency` has a small impact on the flow on `c_monitored`and there is little point in including this constraint in the model. This can be achieved by setting the `commodity_lodf_tolerance` [commodity](@ref) parameter. Contingency / Monotired line combinations with lodfs below this value will be ignored, reducing the size of the model.
   - If `ptdf(n, c)` is very small, it means an injection at n has a small impact on the flow on c and there is little point in considering it. This can be achieved by setting the `commodity_ptdf_threshold` [commodity](@ref) parameter. Node / Monotired line combinations with ptdfs below this value will be ignored, reducing the number of coefficients in the model.
   - To more easily identify which connections are worth being monitored or which contingencies are worth being considered, you can add the `contingency_is_binding` output to any of your [report](@ref)s (via a [report__output](@ref) relationship). This will run the model without the security constraints, and instead write a parameter called `contingency_is_binding` to the output database for each pair of contingency and monitored connection. The value of the parameter will be a (possibly stochastic) time-series where a value of one will indicate that the corresponding security constraint is binding, and zero otherwise.
