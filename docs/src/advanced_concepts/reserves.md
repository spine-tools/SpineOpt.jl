# Reserves

To include a requirement of reserve provision in a model, SpineOpt offers the possibility of creating reserve nodes. Of course reserve provision is different from regular operation, because the reserved capacity does not actually get activated. In this section we will take a look at the things that are particular for a reserve node.

## Defining a reserve node

To define a reserve node, the following parameters have to be defined for the relevant node:

* [is\_reserve_node](@ref)  : this boolean parameter indicates that this node is a reserve node.
* [upward\_reserve](@ref)   : this boolean parameter indicates that the demand for reserve provision of this node concerns upward reserves.
* [downward\_reserve](@ref)  : this boolean parameter indicates that the demand for reserve provision of this node concerns downward reserves.
* [reserve\_procurement\_cost](@ref): (optional) this parameter indicates the procurement cost of a unit for a certain reserve product and can be define on a [unit\_\_to\_node](@ref) or [unit\_\_from\_node](@ref) relationship.

