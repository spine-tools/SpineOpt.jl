# Reserves

SpineOpt provides a way to include reserve provision in a model by creating reserve nodes. Reserve provision is different from regular operations as it involves withholding capacity, rather than producing a certain commodity (e.g., energy).

This section covers the reserve concepts, but we highly recommend checking out the tutorial on reserves for a more thorough understanding of how the model is set up. You can find the [reserves tutorial](@ref reserves-tutorial).

## Defining a reserve node

To define a reserve node, the following parameters have to be defined for the relevant node:

* [is\_reserve_node](@ref)  : this boolean parameter indicates that this node is a reserve node.
* [upward\_reserve](@ref)   : this boolean parameter indicates that the demand for reserve provision of this node concerns upward reserves.
* [downward\_reserve](@ref)  : this boolean parameter indicates that the demand for reserve provision of this node concerns downward reserves.
* [reserve\_procurement\_cost](@ref): (optional) this parameter indicates the procurement cost of a unit for a certain reserve product and can be define on a [unit\_\_to\_node](@ref) or [unit\_\_from\_node](@ref) relationship.

## Defining a reserve group

The reserve group definition allows the creation of a [unit flow capacity constraint](../mathematical_formulation/constraints.md#constraint_unit_flow_capacity) where all the unit flows to different commodities, including the reserve provision, are considered to limit the maximum unit capacity.

The definition of the reserve group also allows the creation of [minimum operating point](../mathematical_formulation/constraints.md#constraint_minimum_operating_point), [ramp up](../mathematical_formulation/constraints.md#constraint_ramp_up), and [ramp down](../mathematical_formulation/constraints.md#constraint_ramp_down) constraints, considering flows and reserve provisions.

The relationship between the unit and the node group (i.e., [unit\_\_to\_node](@ref) or [unit\_\_from\_node](@ref)) is essential to define the parameters needed for the constraints (e.g., [unit\_capacity](@ref), [minimum\_operating\_point](@ref), [ramp\_up\_limit](@ref), or [ramp\_down\_limit](@ref)).

## Illustrative examples

In this example, we will consider a unit that can provide upward and downward reserves, along with producing electricity. Therefore, the model needs to consider both characteristics of electricity production and reserve provision in the constraints.

Let's take a look to the [unit flow capacity constraint](../mathematical_formulation/constraints.md#constraint_unit_flow_capacity) and the [minimum operating point](../mathematical_formulation/constraints.md#constraint_minimum_operating_point). For the illustrative example of ramping constraints and reserves, please visit the [illustrative example of the reserve section](@ref ramping-reserves-illustrative-example).

### Unit flow capacity constraint with reserve

Assuming the following parameters, we are considering a fully flexible unit taking into account the definition of the [unit flow capacity constraint](../mathematical_formulation/constraints.md#constraint_unit_flow_capacity):

* `unit_capacity`  : **100**
* `shut_down_limit`: **1**
* `start_up_limit` : **1**

The parameters indicate that the unit capacity is 100 (e.g., 100 MW) and the shutdown and startup limits are 1 p.u. This means that the unit can start up or shut down to its maximum capacity, making it a fully flexible unit.

Taking into account the constraint and the fact that the unit can provide upward reserve and generate electricity, the simplified version of the resulting constraint is a simplified manner:

 ``unit\_flow\_to\_electricity + upwards\_reserve \leq 100 \cdot units\_on``

Here, we can see that the flow to the electricity node depends on the unit's capacity and the upward reserve provision of the unit.

### Minimum operating point constraint with reserve

We need to consider the following parameters for the [minimum operating point](../mathematical_formulation/constraints.md#constraint_minimum_operating_point) constraint:

* `minimum_operating_point`  : **0.25**

This value means that the unit has a *25%* of its capacity as a minimum operating point (i.e., 25 MW). Therefore, the simplified version of the resulting constraint is:

 ``unit\_flow\_to\_electricity - downward\_reserve \geq 25 \cdot units\_on``

Here, the downward reserve limits the flow to the electricity node to ensure that the minimum operating point of the unit is fulfilled.
