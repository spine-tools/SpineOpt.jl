# User Constraints
User constraints allow the user to define arbitrary linear constraints involving most of the problem variables. This section describes this function and how to use it.

## Key User Constraint Concepts
1. **The basic principle**: The basic steps involved in forming a user constraint are:
 - Creating a user constraint object: One creates a new [user\_constraint](@ref) object which will be used as a unique handle for the specific constraint and on which constraint-level parameters will be defined.
  - Specify which variables are involved in the constraint: this generally involves creating a relationship involving the [user\_constraint](@ref) object. For example, specifying the relationship [unit\_\_from\_node\_\_user\_constraint](@ref) specifies that the corresponding [unit\_flow](@ref) variable is involved in the constraint. The table below contains a complete list of variables and the corresponding relationships to set.
  - Specify the variable coefficients: this will generally involve specifying a parameter named `*_coefficient` on the relationship defined above to specify the coefficient on that particular variable in the constraint. For example, to define the coefficient on the [unit\_flow](@ref) variable, one specifies the [unit\_flow\_coefficient](@ref) parameter on the approrpriate [unit\_\_from\_node\__user_constraint](@ref) relationship. The table below contains a complete list of variables and the corresponding coefficient parameters to set.
  - Specify the right-hand-side constant term: The constraint should be formed in conventional form with all constant terms moved to the right-hand side. The right-hand-side constant term is specified by setting the [right\_hand\_side](@ref) [user\_constraint](@ref) parameter.
   - Specify the constraint sense: this is done by setting the [constraint\_sense](@ref) [user\_constraint](@ref) parameter. The allowed values are `==`, `>=` and `<=`.
   - Coefficients can be defined on some parameters themselves. For example, one may specify a coefficient on a node's demand parameter. This is done by specifying the relationship [node\_\_user\_constraint](@ref) and specifying the [demand\_coefficient](@ref) parameter on that relationship
2. **Piecewise unit_flow coefficients**: As described in [operating\_points](@ref), specifying this parameter decomposes the [unit\_flow](@ref) variable into a number of sub operating segment variables named [unit\_flow\_op](@ref) in the model and with an additional index, `i` for the operating segment. The intention of this functionality is to allow [unit\_flow](@ref) coefficients to be defined individually per segment to define a piecewise linear function. To accomplish this, the steps are as described above with the exception that one must define [operating\_points](@ref) on the appropriate [unit\_\_from\_node](@ref) or [unit\_\_to\_node](@ref) as an array type with the dimension corresponding to the number of operating points and then set the [unit\_flow\_coefficient](@ref) for the appropriate [unit\_\_from\_node\_\_user\_constraint](@ref) relationship, also as an array type with the same number of elements. Note that if operating points is defined as an array type with more than one elements, [unit\_flow\_coefficient](@ref) may be defined as either an array or non-array type. However, if [operating\_points](@ref) is of non-array type, corresponding [unit\_flow\_coefficient](@ref)s must also be of non-array types.
3. **Variables, relationships and coefficient guide for user constraints** The table below provides guidance regarding what relationships and coefficients to set for various problem variables and parameters.

| Problem variable / Parameter Name       | Relationship                                          | Parameter                                       |
|:----------------------------------------|:------------------------------------------------------|:------------------------------------------------|
|`unit_flow` (direction=from_node)        |[unit\_\_from\_node\_\_user\_constraint](@ref)         |[unit\_flow\_coefficient](@ref) (non-array type) |
|`unit_flow` (direction=to_node)          |[unit\_\_to\_node\_\_user\_constraint](@ref)           |[unit\_flow\_coefficient](@ref) (non-array type) |
|`unit_flow_op` (direction=from_node)     |[unit\_\_from\_node\_\_user\_constraint](@ref)         |[unit\_flow\_coefficient](@ref) (array type)     |
|`unit_flow_op` (direction=to_node)       |[unit\_\_to\_node\_\_user\_constraint](@ref)           |[unit\_flow\_coefficient](@ref) (array type)     |
|`connection_flow` (direction=from_node)  |[connection\_\_from\_node\_\_user\_constraint](@ref)   |[connection\_flow\_coefficient](@ref)            |
|`connection_flow` (direction=to_node)    |[connection\_\_to\_node\_\_user\_constraint](@ref)     |[connection\_flow\_coefficient](@ref)            |
|`node_state`                             |[node\_\_user\_constraint](@ref)                       |[node\_state\_coefficient](@ref)                 |
|`storages_invested`                      |[node\_\_user\_constraint](@ref)                       |[storages\_invested\_coefficient](@ref)          |
|`storages_invested_available`            |[node\_\_user\_constraint](@ref)                       |[storages\_invested\_available\_coefficient](@ref)|
|`demand`                                 |[node\_\_user\_constraint](@ref)                       |[demand\_coefficient](@ref)                      |
|`units_on`                               |[unit\_\_user\_constraint](@ref)                       |[units\_on\_coefficient](@ref)                   |
|`units_started_up`                       |[unit\_\_user\_constraint](@ref)                       |[units\_started\_up\_coefficient](@ref)          |
|`units_invested`                         |[unit\_\_user\_constraint](@ref)                       |[units\_invested\_coefficient](@ref)             |
|`units_invested_available`               |[unit\_\_user\_constraint](@ref)                       |[units\_invested\_available\_coefficient](@ref)  |
|`connections_invested`                   |[connection\_\_user\_constraint](@ref)                 |[connections\_invested\_coefficient](@ref)       |
|`connections_invested_available`         |[connection\_\_user\_constraint](@ref)                 |[connections\_invested\_available\_coefficient](@ref)|
