# Entity Classes


## `connection`

> A transfer of commodities between nodes. E.g. electricity line, gas pipeline...

>**Related [Entity Classes](@ref):** [connection\_\_from\_node\_\_investment\_group](@ref), [connection\_\_from\_node\_\_user\_constraint](@ref), [connection\_\_from\_node](@ref), [connection\_\_investment\_group](@ref), [connection\_\_investment\_stochastic\_structure](@ref), [connection\_\_investment\_temporal\_block](@ref), [connection\_\_node\_\_node](@ref), [connection\_\_to\_node\_\_investment\_group](@ref), [connection\_\_to\_node\_\_user\_constraint](@ref), [connection\_\_to\_node](@ref), [connection\_\_user\_constraint](@ref) and [stage\_\_output\_\_connection](@ref)

>**Related [Parameters](@ref):** [availability\_factor](@ref), [benders\_starting\_connections\_invested](@ref), [binary\_gas\_flow\_active](@ref), [connection\_fixed\_annual\_cost](@ref), [connection\_investment\_cost](@ref), [connection\_min\_factor](@ref), [connection\_type](@ref), [contingency\_active](@ref), [decommissioning\_cost](@ref), [decommissioning\_time](@ref), [discount\_rate\_technology\_specific](@ref), [existing\_connections](@ref), [investment\_count\_fix\_cumulative](@ref), [investment\_count\_fix\_new](@ref), [investment\_count\_initial\_cumulative](@ref), [investment\_count\_initial\_new](@ref), [investment\_count\_max\_cumulative](@ref), [investment\_variable\_type](@ref), [lead\_time](@ref), [lifetime\_constraint\_sense](@ref), [lifetime\_economic](@ref), [lifetime\_technical](@ref), [mga\_investment\_active](@ref), [mga\_investment\_big\_m](@ref), [mga\_investment\_weight](@ref), [monitoring\_active](@ref), [reactance\_base](@ref), [reactance](@ref) and [resistance](@ref)

>**Related [parameter\_types](@ref):** [binary\_gas\_flow\_active](@ref), [connection\_type](@ref), [contingency\_active](@ref), [decommissioning\_time](@ref), [investment\_variable\_type](@ref), [lead\_time](@ref), [lifetime\_constraint\_sense](@ref), [lifetime\_economic](@ref), [lifetime\_technical](@ref), [mga\_investment\_active](@ref) and [monitoring\_active](@ref)

A [connection](@ref) represents a transfer of one commodity over space.
For example, an electricity transmission line, a gas pipe, a river branch,
can be modelled using a [connection](@ref).

A [connection](@ref) always takes commodities from one or more [node](@ref)s, and releases them to
one or more (possibly the same) [node](@ref)s.
The former are specificed through the [connection\_\_from\_node](@ref) relationship,
and the latter through [connection\_\_to\_node](@ref).
Every [connection](@ref) inherits the temporal and stochastic structures from the associated nodes.
The model will generate `connection_flow` variables for every combination of
[connection](@ref), [node](@ref), *direction* (from node or to node), *time slice*, and *stochastic scenario*,
according to the above relationships.

The operation of the [connection](@ref) is specified through a number of parameter values.
For example, the capacity of the connection, as the maximum amount of energy that can enter or leave it,
is given by [capacity\_per\_connection](@ref).
The conversion ratio of input to output can be specified using any of [fix\_ratio\_out\_in\_connection\_flow](@ref),
[max\_ratio\_out\_in\_connection\_flow](@ref), and [min\_ratio\_out\_in\_connection\_flow](@ref) parameters
in the [connection\_\_node\_\_node](@ref) relationship.
The delay on a connection, as the time it takes for the energy to go from one end to the other,
is given by [connection\_flow\_delay](@ref).
## `connection__from_node`

> A flow on a `connection` from a `node`.

>**Related [Entity Classes](@ref):** [connection](@ref) and [node](@ref)

>**Related [Parameters](@ref):** [binary\_gas\_flow\_limits\_fix](@ref), [binary\_gas\_flow\_limits\_initial](@ref), [capacity\_per\_connection](@ref), [capacity\_to\_flow\_conversion\_factor](@ref), [connection\_emergency\_capacity](@ref), [connection\_flow\_cost](@ref), [connection\_flow\_non\_anticipativity\_margin](@ref), [connection\_flow\_non\_anticipativity\_time](@ref), [connection\_intact\_flow\_non\_anticipativity\_margin](@ref), [connection\_intact\_flow\_non\_anticipativity\_time](@ref), [flow\_limits\_fix\_intact](@ref), [flow\_limits\_fix](@ref), [flow\_limits\_initial\_intact](@ref) and [flow\_limits\_initial](@ref)

>**Related [parameter\_types](@ref):** [connection\_flow\_non\_anticipativity\_time](@ref) and [connection\_intact\_flow\_non\_anticipativity\_time](@ref)

`connection__from_node` is a two-dimensional relationship between a [connection](@ref) and a [node](@ref) and implies a `connection_flow` to the [connection](@ref) from the [node](@ref). Specifying such a relationship will give rise to a `connection_flow_variable` with indices `connection=connection, node=node, direction=:from_node`. Relationships defined on this relationship will generally apply to this specific flow variable. For example, [capacity_per_connection](@ref) will apply only to this specific flow variable, unless the connection parameter [connection_type](@ref) is specified.
## `connection__from_node__investment_group`

> A flow on a `connection` from a `node` whose capacity should be counted in the capacity invested available of an `investment_group`.

>**Related [Entity Classes](@ref):** [connection](@ref), [investment\_group](@ref) and [node](@ref)


## `connection__from_node__user_constraint`

> A flow on a `connection` from a `node` constrained by a `user_constraint`.

>**Related [Entity Classes](@ref):** [connection](@ref), [node](@ref) and [user\_constraint](@ref)

>**Related [Parameters](@ref):** [coefficient\_for\_connection\_flow](@ref)

`connection__from_node__user_constraint` is a three-dimensional relationship between a [connection](@ref), a [node](@ref) and a [user_constraint](@ref). The relationship specifies that the `connection_flow` variable to the specified [connection](@ref) from the specified [node](@ref) is involved in the specified [user_constraint](@ref). Parameters on this relationship generally apply to this specific `connection_flow` variable. For example the parameter [coefficient\_for\_connection\_flow](@ref) defined on `connection__from_node__user_constraint` represents the coefficient on the specific `connection_flow` variable in the specified [user_constraint](@ref)

## `connection__investment_group`

> A `connection` that belongs in an `investment_group`.

>**Related [Entity Classes](@ref):** [connection](@ref) and [investment\_group](@ref)


## `connection__investment_stochastic_structure`

> The `stochastic_structure` of a `connection` investment.

>**Related [Entity Classes](@ref):** [connection](@ref) and [stochastic\_structure](@ref)

The [connection\_\_investment\_stochastic\_structure](@ref) relationship defines the [stochastic\_structure](@ref)
of [connection](@ref)-related investment decisions.
Essentially, it sets the [stochastic\_structure](@ref) used by the [connections\_invested\_available](@ref) variable of the [connection](@ref).

The [connection\_\_investment\_stochastic\_structure](@ref) relationship uses the
[model\_\_default\_investment\_stochastic\_structure](@ref) relationship if not defined.

## `connection__investment_temporal_block`

> The `temporal_block` of a `connection` investment.

>**Related [Entity Classes](@ref):** [connection](@ref) and [temporal\_block](@ref)

`connection__investment_temporal_block` is a two-dimensional relationship between a [connection](@ref) and a [temporal_block](@ref). This relationship defines the temporal resolution and scope of a connection's investment decision. Note that in a decomposed investments problem with two model objects, one for the master problem model and another for the operations problem model, the link to the specific model is made indirectly through the [model__temporal_block](@ref) relationship. If a [model\_\_default\_investment\_temporal\_block](@ref) is specified and no `connection__investment_temporal_block` relationship is specified, the [model\_\_default\_investment\_temporal\_block](@ref) relationship will be used. Conversely if `connection__investment_temporal_block` is specified along with [model__temporal_block](@ref), this will override [model\_\_default\_investment\_temporal\_block](@ref) for the specified [connection](@ref).

See also [Investment Optimization](@ref)

## `connection__node__node`

> A `connection` acting over two `node`s.

>**Related [Entity Classes](@ref):** [connection](@ref) and [node](@ref)

>**Related [Parameters](@ref):** [compression\_factor](@ref), [connection\_flow\_delay](@ref), [connection\_linepack\_constant](@ref), [fix\_ratio\_out\_in\_connection\_flow](@ref), [fixed\_pressure\_constant\_0](@ref), [fixed\_pressure\_constant\_1](@ref), [max\_ratio\_out\_in\_connection\_flow](@ref) and [min\_ratio\_out\_in\_connection\_flow](@ref)

>**Related [parameter\_types](@ref):** [connection\_flow\_delay](@ref)

`connection__node__node` is a three-dimensional relationship between a [connection](@ref), a [node](@ref) (node 1) and another [node](@ref) (node 2). `connection__node__node` infers a conversion and a direction with respect to that conversion. Node 1 is assumed to be the input node and node 2 is assumed to be the output node. For example, the [fix\_ratio\_out\_in\_connection\_flow](@ref) parameter defined on `connection__node__node` relates the output `connection_flow` to node 2 to the intput `connection_flow` from node 1

## `connection__to_node`

> A flow on a `connection` to a `node` .

>**Related [Entity Classes](@ref):** [connection](@ref) and [node](@ref)

>**Related [Parameters](@ref):** [binary\_gas\_flow\_limits\_fix](@ref), [binary\_gas\_flow\_limits\_initial](@ref), [capacity\_per\_connection](@ref), [capacity\_to\_flow\_conversion\_factor](@ref), [connection\_emergency\_capacity](@ref), [connection\_flow\_cost](@ref), [connection\_flow\_non\_anticipativity\_margin](@ref), [connection\_flow\_non\_anticipativity\_time](@ref), [connection\_intact\_flow\_non\_anticipativity\_margin](@ref), [connection\_intact\_flow\_non\_anticipativity\_time](@ref), [flow\_limits\_fix\_intact](@ref), [flow\_limits\_fix](@ref), [flow\_limits\_initial\_intact](@ref) and [flow\_limits\_initial](@ref)

`connection__to_node` is a two-dimensional relationship between a [connection](@ref) and a [node](@ref) and implies a `connection_flow` from the [connection](@ref) to the [node](@ref). Specifying such a relationship will give rise to a `connection_flow_variable` with indices `connection=connection, node=node, direction=:to_node`. Relationships defined on this relationship will generally apply to this specific flow variable. For example, [capacity_per_connection](@ref) will apply only to this specific flow variable, unless the connection parameter [connection_type](@ref) is specified.
## `connection__to_node__investment_group`

> A flow on a `connection` to a `node` whose capacity should be counted in the capacity invested available of an `investment_group`.

>**Related [Entity Classes](@ref):** [connection](@ref), [investment\_group](@ref) and [node](@ref)


## `connection__to_node__user_constraint`

> A flow on a `connection` to a `node` constrained by a `user_constraint

>**Related [Entity Classes](@ref):** [connection](@ref), [node](@ref) and [user\_constraint](@ref)

>**Related [Parameters](@ref):** [coefficient\_for\_connection\_flow](@ref)

`connection__to_node__user_constraint` is a three-dimensional relationship between a [connection](@ref), a [node](@ref) and a [user_constraint](@ref). The relationship specifies that the `connection_flow` variable from the specified [connection](@ref) to the specified [node](@ref) is involved in the specified [user_constraint](@ref). Parameters on this relationship generally apply to this specific `connection_flow` variable. For example the parameter [coefficient\_for\_connection\_flow](@ref) defined on `connection__to_node__user_constraint` represents the coefficient on the specific `connection_flow` variable in the specified [user_constraint](@ref)

## `connection__user_constraint`

> A `connection` investment constrained by a `user_constraint`.

>**Related [Entity Classes](@ref):** [connection](@ref) and [user\_constraint](@ref)

>**Related [Parameters](@ref):** [coefficient\_for\_connections\_invested\_available](@ref) and [coefficient\_for\_connections\_invested](@ref)


## `grid`

> A good or product that can be consumed, produced, traded. E.g., electricity, oil, gas, water...

>**Related [Entity Classes](@ref):** [node\_\_grid](@ref)

>**Related [Parameters](@ref):** [lodf\_tolerance](@ref), [mp\_min\_res\_gen\_to\_demand\_ratio\_slack\_penalty](@ref), [mp\_min\_res\_gen\_to\_demand\_ratio](@ref), [physics\_duration](@ref), [physics\_type](@ref) and [ptdf\_threshold](@ref)

>**Related [parameter\_types](@ref):** [physics\_duration](@ref) and [physics\_type](@ref)

Grids are for trading different types of commodities. When associated with a [node](@ref) through the [node\_\_grid](@ref) relationship, a specific location can be associated with a specific grid (or form of commodity). 
For the representation of specific grid physics, related to e.g. the representation of the electric network, designated parameters can be defined to enforce grid specific behaviour. (See also [physics\_type](@ref))

## `investment_group`

> A group of investments that need to be done together.

>**Related [Entity Classes](@ref):** [connection\_\_from\_node\_\_investment\_group](@ref), [connection\_\_investment\_group](@ref), [connection\_\_to\_node\_\_investment\_group](@ref), [node\_\_investment\_group](@ref), [unit\_\_investment\_group](@ref) and [unit\_flow\_\_investment\_group](@ref)

>**Related [Parameters](@ref):** [equal\_investments\_active](@ref), [investment\_capacity\_total\_max\_cumulative](@ref), [investment\_capacity\_total\_min\_cumulative](@ref), [investment\_count\_total\_max\_cumulative](@ref) and [investment\_count\_total\_min\_cumulative](@ref)

>**Related [parameter\_types](@ref):** [equal\_investments\_active](@ref)

The [investment\_group](@ref) class represents a group of investments that need to be done together.
For example, a storage investment on a [node](@ref) might only make sense if done together with a [unit](@ref)
or a [connection](@ref) investment.

To use this functionality, you must first create an [investment\_group](@ref) and then
specify any number of [unit\_\_investment\_group](@ref), [node\_\_investment\_group](@ref), and/or
[connection\_\_investment\_group](@ref) relationships between your [investment\_group](@ref)
and the [unit](@ref), [node](@ref), and/or [connection](@ref) investments that you want to be done together.
This will ensure that the investment variables of all the entities in the [investment\_group](@ref)
have the same value.

## `model`

> An instance of SpineOpt, that specifies general parameters such as the temporal horizon.

>**Related [Entity Classes](@ref):** [model\_\_default\_investment\_stochastic\_structure](@ref), [model\_\_default\_investment\_temporal\_block](@ref), [model\_\_default\_stochastic\_structure](@ref), [model\_\_default\_temporal\_block](@ref) and [model\_\_report](@ref)

>**Related [Parameters](@ref):** [benders\_iterations\_reporting\_active](@ref), [big\_m](@ref), [connection\_flow\_highest\_resolution\_active](@ref), [connection\_investment\_power\_flow\_impact\_active](@ref), [decomposition\_max\_gap](@ref), [decomposition\_max\_iterations](@ref), [decomposition\_min\_iterations](@ref), [discount\_rate](@ref), [discount\_year](@ref), [duration\_unit](@ref), [mga\_max\_iterations](@ref), [mga\_max\_slack](@ref), [model\_algorithm](@ref), [model\_end](@ref), [model\_start](@ref), [model\_type](@ref), [monte\_carlo\_scenarios](@ref), [multiyear\_economic\_discounting](@ref), [roll\_forward](@ref), [shared\_values](@ref), [solver\_lp\_options](@ref), [solver\_lp](@ref), [solver\_mip\_options](@ref), [solver\_mip](@ref), [tight\_compact\_formulations\_active](@ref), [window\_duration](@ref), [window\_weight](@ref), [write\_lodf\_file](@ref), [write\_mps\_file](@ref) and [write\_ptdf\_file](@ref)

>**Related [parameter\_types](@ref):** [benders\_iterations\_reporting\_active](@ref), [connection\_flow\_highest\_resolution\_active](@ref), [connection\_investment\_power\_flow\_impact\_active](@ref), [discount\_year](@ref), [duration\_unit](@ref), [model\_algorithm](@ref), [model\_end](@ref), [model\_start](@ref), [model\_type](@ref), [roll\_forward](@ref), [solver\_lp\_options](@ref), [solver\_lp](@ref), [solver\_mip\_options](@ref), [solver\_mip](@ref), [tight\_compact\_formulations\_active](@ref), [window\_duration](@ref), [write\_lodf\_file](@ref), [write\_mps\_file](@ref) and [write\_ptdf\_file](@ref)

The model object holds general information about the optimization problem at hand. Firstly, the modelling horizon is specified on the model object, i.e. the scope of the optimization model, and if applicable the duration of the rolling window (see also [model\_start](@ref), [model\_end](@ref) and [roll\_forward](@ref)). Secondly, the model works as an overarching assembler - only through linking [temporal\_block](@ref)s and [stochastic\_structure](@ref)s to a model object via relationships, they become part of the optimization problem, and respectively linked nodes, connections and units. If desired the user can also specify defaults for temporals and stochastic via the designated default relationships (see e.g., [model\_\_default\_temporal\_block](@ref)). In this case, the default temporal is populated for missing [node\_\_temporal\_block](@ref) relationships.
Lastly, the model object contains information about the algorithm used for solving the problem (see [model\_type](@ref)).

## `model__default_investment_stochastic_structure`

> The default `stochastic_structure` of all investments in the `model`.

>**Related [Entity Classes](@ref):** [model](@ref) and [stochastic\_structure](@ref)

The [model\_\_default\_investment\_stochastic\_structure](@ref) relationship can be used to set [model](@ref)-wide
default [unit\_\_investment\_stochastic\_structure](@ref), [connection\_\_investment\_stochastic\_structure](@ref),
and [node\_\_investment\_stochastic\_structure](@ref) relationships.
Its main purpose is to allow users to avoid defining each relationship individually,
and instead allow them to focus on defining only the exceptions.
As such, any specific [unit\_\_investment\_stochastic\_structure](@ref),
[connection\_\_investment\_stochastic\_structure](@ref), and [node\_\_investment\_stochastic\_structure](@ref)
relationships take priority over the [model\_\_default\_investment\_stochastic\_structure](@ref) relationship.
## `model__default_investment_temporal_block`

> The default `temporal_block` of all investments in the `model`.

>**Related [Entity Classes](@ref):** [model](@ref) and [temporal\_block](@ref)

`model__default_investment_temporal_block` is a two-dimensional relationship between a [model](@ref) and a [temporal_block](@ref). This relationship defines the default temporal resolution and scope for all investment decisions in the model ([units](@ref unit), [connections](@ref connection) and storages). Specifying `model__default_investment_temporal_block` for a model avoids the need to specify individual [node\_\_investment\_temporal\_block](@ref), [unit\_\_investment\_temporal\_block](@ref) and [connection\_\_investment\_temporal\_block](@ref) relationships. Conversely, if any of these individual relationships are defined (e.g. [connection\_\_investment\_temporal\_block](@ref)) along with [model\_\_temporal\_block](@ref), these will override [model\_\_default\_investment\_temporal\_block](@ref).

See also [Investment Optimization](@ref)

## `model__default_stochastic_structure`

> The default `stochastic_structure` of the `model.

>**Related [Entity Classes](@ref):** [model](@ref) and [stochastic\_structure](@ref)

The [model\_\_default\_stochastic\_structure](@ref) relationship can be used to set a [model](@ref)-wide default
for the [node\_\_stochastic\_structure](@ref) and [units\_on\_\_stochastic\_structure](@ref) relationships.
Its main purpose is to allow users to avoid defining each relationship individually,
and instead allow them to focus on defining only the exceptions.
As such, any specific [node\_\_stochastic\_structure](@ref) or [units\_on\_\_stochastic\_structure](@ref)
relationships take priority over the [model\_\_default\_stochastic\_structure](@ref) relationship.
## `model__default_temporal_block`

> The default `temporal_block` of the `model`.

>**Related [Entity Classes](@ref):** [model](@ref) and [temporal\_block](@ref)

The [model\_\_default\_temporal\_block](@ref) relationship can be used to set a [model](@ref)-wide default
for the [node\_\_temporal\_block](@ref) and [units\_on\_\_temporal\_block](@ref) relationships.
Its main purpose is to allow users to avoid defining each relationship individually,
and instead allow them to focus on defining only the exceptions.
As such, any specific [node\_\_temporal\_block](@ref) or [units\_on\_\_temporal\_block](@ref)
relationships take priority over the [model\_\_default\_temporal\_block](@ref) relationship.

## `model__report`

> A `report` that should be written for the `model`.

>**Related [Entity Classes](@ref):** [model](@ref) and [report](@ref)

The [model\_\_report](@ref) relationship tells which [report](@ref)s are written by which [model](@ref),
where the contents of the [report](@ref)s are defined separately using the [report\_\_output](@ref) relationship.
Without appropriately defined [model\_\_report](@ref) and [report\_\_output](@ref) and relationships,
*SpineOpt* doesn't write any output, so be sure to include at least one [report](@ref)
connected to all the [output](@ref) [variables](@ref Variables) of interest in the [model](@ref)!
## `node`

> A universal aggregator of commodify flows over units and connections, with storage capabilities.

>**Related [Entity Classes](@ref):** [connection\_\_from\_node\_\_investment\_group](@ref), [connection\_\_from\_node\_\_user\_constraint](@ref), [connection\_\_from\_node](@ref), [connection\_\_node\_\_node](@ref), [connection\_\_to\_node\_\_investment\_group](@ref), [connection\_\_to\_node\_\_user\_constraint](@ref), [connection\_\_to\_node](@ref), [node\_\_grid](@ref), [node\_\_investment\_group](@ref), [node\_\_investment\_stochastic\_structure](@ref), [node\_\_investment\_temporal\_block](@ref), [node\_\_node](@ref), [node\_\_stochastic\_structure](@ref), [node\_\_temporal\_block](@ref), [node\_\_to\_unit](@ref), [node\_\_user\_constraint](@ref), [stage\_\_output\_\_node](@ref) and [unit\_\_to\_node](@ref)

>**Related [Parameters](@ref):** [balance\_penalty](@ref), [balance\_sense](@ref), [balance\_type](@ref), [benders\_starting\_storages\_invested](@ref), [capacity\_margin\_min](@ref), [capacity\_margin\_penalty](@ref), [demand\_fraction](@ref), [demand](@ref), [existing\_storages](@ref), [is\_non\_spinning](@ref), [mga\_storage\_investment\_active](@ref), [mga\_storage\_investment\_big\_m](@ref), [mga\_storage\_investment\_weight](@ref), [minimum\_reserve\_activation\_time](@ref), [node\_opf\_type](@ref), [pressure\_fix](@ref), [pressure\_initial](@ref), [pressure\_max](@ref), [pressure\_min](@ref), [reserve\_active](@ref), [reserve\_downward](@ref), [reserve\_upward](@ref), [storage\_active](@ref), [storage\_decommissioning\_cost](@ref), [storage\_decommissioning\_time](@ref), [storage\_discount\_rate\_technology\_specific](@ref), [storage\_fixed\_annual\_cost](@ref), [storage\_investment\_cost](@ref), [storage\_investment\_count\_fix\_cumulative](@ref), [storage\_investment\_count\_fix\_new](@ref), [storage\_investment\_count\_initial\_cumulative](@ref), [storage\_investment\_count\_initial\_new](@ref), [storage\_investment\_count\_max\_cumulative](@ref), [storage\_investment\_variable\_type](@ref), [storage\_lead\_time](@ref), [storage\_lifetime\_constraint\_sense](@ref), [storage\_lifetime\_economic](@ref), [storage\_lifetime\_technical](@ref), [storage\_longterm\_active](@ref), [storage\_self\_discharge](@ref), [storage\_state\_coefficient](@ref), [storage\_state\_fix](@ref), [storage\_state\_initial](@ref), [storage\_state\_max\_fraction](@ref), [storage\_state\_max](@ref), [storage\_state\_min\_fraction](@ref), [storage\_state\_min](@ref), [tax\_in\_unit\_flow](@ref), [tax\_net\_unit\_flow](@ref), [tax\_out\_unit\_flow](@ref), [voltage\_angle\_fix](@ref), [voltage\_angle\_initial](@ref), [voltage\_angle\_max](@ref) and [voltage\_angle\_min](@ref)

>**Related [parameter\_types](@ref):** [balance\_sense](@ref), [balance\_type](@ref), [is\_non\_spinning](@ref), [mga\_storage\_investment\_active](@ref), [minimum\_reserve\_activation\_time](@ref), [node\_opf\_type](@ref), [reserve\_active](@ref), [reserve\_downward](@ref), [reserve\_upward](@ref), [storage\_active](@ref), [storage\_decommissioning\_time](@ref), [storage\_investment\_variable\_type](@ref), [storage\_lead\_time](@ref), [storage\_lifetime\_constraint\_sense](@ref), [storage\_lifetime\_economic](@ref), [storage\_lifetime\_technical](@ref) and [storage\_longterm\_active](@ref)

The [node](@ref) is perhaps the most important `object class` out of the [Systemic object classes](@ref),
as it is what connects the rest together via the [Systemic relationship classes](@ref).
Essentially, [node](@ref)s act as points in the modelled [grid](@ref)
where commodity balance is enforced via the [node balance](@ref constraint_nodal_balance) and [node injection](@ref constraint_node_injection) constraints,
tying together the inputs and outputs from [unit](@ref)s and [connection](@ref)s,
as well as any external [demand](@ref).
Furthermore, [node](@ref)s play a crucial role for defining the temporal and stochastic structures of the [model](@ref)
via the [node\_\_temporal\_block](@ref) and [node\_\_stochastic\_structure](@ref) relationships.
For more details about the [Temporal Framework](@ref) and the [Stochastic Framework](@ref), please refer to the
dedicated sections.

Since [node](@ref)s act as the points where commodity balance is enforced,
this also makes them a natural fit for implementing *storage*.
The [storage\_active](@ref) parameter controls whether a [node](@ref) has a `node_state` variable,
which essentially represents the commodity content of the [node](@ref).
The [storage\_state\_coefficient](@ref) parameter tells how the `node_state` variable relates to all the commodity flows.
Storage losses are handled via the [storage\_self\_discharge](@ref) parameter,
and potential diffusion of commodity content to other [node](@ref)s via the [diffusion\_coefficient](@ref) parameter for the
[node\_\_node](@ref) relationship.

## `node__grid`

> The `grid` the `node` is connected to. Only a single `grid` is permitted per `node`.

>**Related [Entity Classes](@ref):** [grid](@ref) and [node](@ref)

`node__grid` is a two-dimensional relationship between a [node](@ref) and a [grid](@ref) and specifies the grid that the node belongs to or the type of commodity that `flows` to or from the node. Generally, since flows are not dimensioned by [grid](@ref), this has no meaning in terms of the variables and constraint equations. However, there are two specific uses for this relationship:
1. To specify that specific network physics should apply to the network formed by the member nodes for that grid. See [powerflow](@ref ptdf-based-powerflow)
2. Only connection flows that are between nodes of the same or no [grid](@ref) are included in the `node_balance` constraint.

## `node__investment_group`

> A `node` that belongs in an `investment_group`.

>**Related [Entity Classes](@ref):** [investment\_group](@ref) and [node](@ref)


## `node__investment_stochastic_structure`

> The `stochastic_structure` of a `node` storage investment.

>**Related [Entity Classes](@ref):** [node](@ref) and [stochastic\_structure](@ref)

The [node\_\_investment\_stochastic\_structure](@ref) relationship defines the [stochastic\_structure](@ref)
of [node](@ref)-related investment decisions.
Essentially, it sets the [stochastic\_structure](@ref) used by the [storages\_invested\_available](@ref) variable of the [node](@ref).

The [node\_\_investment\_stochastic\_structure](@ref) relationship uses the
[model\_\_default\_investment\_stochastic\_structure](@ref) relationship if not defined.

## `node__investment_temporal_block`

> The `temporal_block` of a `node` storage investment.

>**Related [Entity Classes](@ref):** [node](@ref) and [temporal\_block](@ref)

`node__investment_temporal_block` is a two-dimensional relationship between a [node](@ref) and a [temporal_block](@ref). This relationship defines the temporal resolution and scope of a [node](@ref)'s investment decisions (currently only storage invesments). Note that in a decomposed investments problem with two model objects, one for the master problem model and another for the operations problem model, the link to the specific model is made indirectly through the [model__temporal_block](@ref) relationship. If a [model\_\_default\_investment\_temporal\_block](@ref) is specified and no `node__investment_temporal_block` relationship is specified, the [model\_\_default\_investment\_temporal\_block](@ref) relationship will be used. Conversely if `node__investment_temporal_block` is specified along with [model__temporal_block](@ref), this will override [model\_\_default\_investment\_temporal\_block](@ref) for the specified [node](@ref).

See also [Investment Optimization](@ref)

## `node__node`

> An interaction between two `node`s.

>**Related [Entity Classes](@ref):** [node](@ref)

>**Related [Parameters](@ref):** [diffusion\_coefficient](@ref)

The [node\_\_node](@ref) relationship is used for defining direct interactions between two [node](@ref)s,
like diffusion of commodity content.
Note that the [node\_\_node](@ref) relationship is assumed to be one-directional,
meaning that
```julia
node__node(node1=n1, node2=n2) != node__node(node1=n2, node2=n1).
```
Thus, when one wants to define *symmetric relationships* between two [node](@ref)s,
one needs to define both directions as separate relationships.
## `node__stochastic_structure`

> The `stochastic_structure` of a `node`. Only one `stochastic_structure` is permitted per `node`.

>**Related [Entity Classes](@ref):** [node](@ref) and [stochastic\_structure](@ref)

The [node\_\_stochastic\_structure](@ref) relationship defines which [stochastic\_structure](@ref) the [node](@ref) uses.
Essentially, it sets the [stochastic\_structure](@ref) of all the `flow` [variables](@ref Variables) connected
to the [node](@ref), as well as the potential [node\_state](@ref) variable.
Note that only one [stochastic\_structure](@ref) can be defined per [node](@ref) per [model](@ref),
as interpreted based on the [node\_\_stochastic\_structure](@ref) and [model\_\_stochastic\_structure](@ref)
relationships.
Investment [variables](@ref Variables) use dedicated relationships, as detailed in the [Investment Optimization](@ref) section.

The [node\_\_stochastic\_structure](@ref) relationship uses the [model\_\_default\_stochastic\_structure](@ref)
relationship if not specified.

## `node__temporal_block`

> The `temporal_block` of a `node` and the corresponding `flow` variables.

>**Related [Entity Classes](@ref):** [node](@ref) and [temporal\_block](@ref)

>**Related [Parameters](@ref):** [cyclic\_condition\_sense](@ref) and [cyclic\_condition](@ref)

>**Related [parameter\_types](@ref):** [cyclic\_condition\_sense](@ref) and [cyclic\_condition](@ref)

This relationship links a [node](@ref) to a [temporal_block](@ref) and as such it will determine which temporal block governs the temporal horizon and resolution of the variables associated with this node. Specifically, the [resolution](@ref) of the temporal block will directly imply the duration of the time slices for which both the [flow variables](@ref Variables) and their associated constraints are created.

For a more detailed description of how the temporal structure in SpineOpt can be created, see [Temporal Framework](@ref).

## `node__to_unit`

> A flow on a `unit` from a `node`.

>**Related [Entity Classes](@ref):** [node](@ref) and [unit](@ref)

>**Related [Parameters](@ref):** [capacity\_per\_unit](@ref), [capacity\_to\_flow\_conversion\_factor](@ref), [fix\_nonspin\_units\_started\_up](@ref), [flow\_limits\_fix\_op](@ref), [flow\_limits\_fix](@ref), [flow\_limits\_initial\_op](@ref), [flow\_limits\_initial](@ref), [flow\_limits\_max\_cumulative](@ref), [flow\_limits\_min\_cumulative](@ref), [flow\_limits\_min](@ref), [fuel\_cost](@ref), [initial\_nonspin\_units\_started\_up](@ref), [minimum\_operating\_point](@ref), [operating\_points](@ref), [ordered\_unit\_flow\_op](@ref), [ramp\_limits\_down](@ref), [ramp\_limits\_shutdown](@ref), [ramp\_limits\_startup](@ref), [ramp\_limits\_up](@ref), [reserve\_procurement\_cost](@ref), [unit\_flow\_non\_anticipativity\_margin](@ref), [unit\_flow\_non\_anticipativity\_time](@ref) and [vom\_cost](@ref)

>**Related [parameter\_types](@ref):** [ordered\_unit\_flow\_op](@ref) and [unit\_flow\_non\_anticipativity\_time](@ref)

The [unit\_\_to\_node](@ref) and [node\_\_to\_unit](@ref) unit relationships are core elements of SpineOpt.
For each [unit\_\_to\_node](@ref) or [node\_\_to\_unit](@ref), a [unit\_flow](@ref) variable is automatically
added to the model, i.e.
a commodity flow of a unit to or from a specific node, respectively.

Various parameters can be defined on the [node\_\_to\_unit](@ref) relationship, in order to
constrain the associated unit flows. In most cases a [capacity\_per\_unit](@ref) will be defined for
an upper bound on the commodity flows. Apart from that, ramping abilities of a unit can be
defined. For further details on ramps see [Ramping](@ref).

To associate costs with a certain commodity flows, cost terms, such as [fuel\_cost](@ref)s and [vom\_cost](@ref)s,
can be included for the [node\_\_to\_unit](@ref) relationship.

It is important to note, that the parameters associated with the [node\_\_to\_unit](@ref) can be defined either
for a specific [node](@ref), or for a group of nodes. Grouping nodes for the described parameters will result
in an aggregation of the unit flows for the triggered constraint, e.g. the definition of the [capacity\_per\_unit](@ref)
on a group of nodes will result in an upper bound on the sum of all individual [unit\_flow](@ref)s.

## `node__user_constraint`

> A `node` state constrained by a `user_constraint`, or a `node` demand included in a `user_constraint`.

>**Related [Entity Classes](@ref):** [node](@ref) and [user\_constraint](@ref)

>**Related [Parameters](@ref):** [coefficient\_for\_demand](@ref), [coefficient\_for\_node\_state](@ref), [coefficient\_for\_storages\_invested\_available](@ref) and [coefficient\_for\_storages\_invested](@ref)

`node__user_constraint` is a two-dimensional relationship between a [node](@ref) and a [user_constraint](@ref). The relationship specifies that a variable associated only with the node (currently only the `node_state`) is involved in the constraint. For example, the [coefficient\_for\_node\_state](@ref) defined on `node__user_constraint` specifies the coefficient of the [node](@ref)'s `node_state` variable in the specified [user_constraint](@ref).

See also [user_constraint](@ref)

## `output`

> A variable name from SpineOpt whose value can be included in a report.

>**Related [Entity Classes](@ref):** [report\_\_output](@ref), [stage\_\_output\_\_connection](@ref), [stage\_\_output\_\_node](@ref), [stage\_\_output\_\_unit](@ref) and [stage\_\_output](@ref)

>**Related [Parameters](@ref):** [output\_resolution](@ref) and [output\_type](@ref)

>**Related [parameter\_types](@ref):** [output\_resolution](@ref) and [output\_type](@ref)

An [output](@ref) is essentially a handle for a *SpineOpt* [variable](@ref Variables) and
[Objective function](@ref) to be included in a [report](@ref) and written into an output database.
Typically, e.g. the [unit\_flow](@ref) variables are desired as output from most [model](@ref)s,
so creating an [output](@ref) object called `unit_flow` allows one to designate it as something to be written in the
desired [report](@ref).
Note that unless appropriate [model\_\_report](@ref) and [report\_\_output](@ref) relationships are defined,
*SpineOpt* doesn't write any output!
## `parent_stochastic_scenario__child_stochastic_scenario`

> A parent-child relationship between two `stochastic_scenario`s defining the master stochastic direct acyclic graph.

>**Related [Entity Classes](@ref):** [stochastic\_scenario](@ref)

The [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationship defines how the individual
[stochastic\_scenario](@ref)s are related to each other, forming what is referred to as the
*stochastic direct acyclic graph (DAG)* in the [Stochastic Framework](@ref) section.
It acts as a sort of basis for the [stochastic\_structure](@ref)s, but doesn't contain any [Parameters](@ref)
necessary for describing how it relates to the [Temporal Framework](@ref) or the [Objective function](@ref).

The [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationship and the *stochastic DAG* it forms
are crucial for [Constraint generation with stochastic path indexing](@ref).
Every finite *stochastic DAG* has a limited number of unique ways of traversing it, called *full stochastic paths*,
which are used when determining how many different constraints need to be generated over time periods where
[stochastic\_structure](@ref)s branch or converge, or when generating constraints involving different
[stochastic\_structure](@ref)s.
See the [Stochastic Framework](@ref) section for more information.
## `report`

> A results report from a particular SpineOpt run, including the value of specific variables.

>**Related [Entity Classes](@ref):** [model\_\_report](@ref) and [report\_\_output](@ref)

>**Related [Parameters](@ref):** [output\_db\_url](@ref)

>**Related [parameter\_types](@ref):** [output\_db\_url](@ref)

A [report](@ref) is essentially a group of [output](@ref)s from a [model](@ref),
that gets written into the output database as a result of running *SpineOpt*.
Note that unless appropriate [model\_\_report](@ref) and [report\_\_output](@ref) relationships are defined,
*SpineOpt* doesn't write any output!
## `report__output`

> An `output` that should be included in a `report`.

>**Related [Entity Classes](@ref):** [output](@ref) and [report](@ref)

>**Related [Parameters](@ref):** [overwrite\_results\_on\_rolling](@ref)

>**Related [parameter\_types](@ref):** [overwrite\_results\_on\_rolling](@ref)

The [report\_\_output](@ref) relationship tells which [output](@ref) [variables](@ref Variables) to include
in which [report](@ref) when writing *SpineOpt* output.
Note that the [report](@ref)s also need to be connected to a [model](@ref) using the [model\_\_report](@ref) relationship.
Without appropriately defined [model\_\_report](@ref) and [report\_\_output](@ref) and relationships,
*SpineOpt* doesn't write any output, so be sure to include at least one [report](@ref)
connected to all the [output](@ref) [variables](@ref Variables) of interest in the [model](@ref)!
## `settings`

> Internal SpineOpt settings. We kindly advise not to mess with this one.

>**Related [Parameters](@ref):** [version](@ref)

>**Related [parameter\_types](@ref):** [version](@ref)


## `stage`

> An additional stage in the optimisation problem (EXPERIMENTAL)

>**Related [Entity Classes](@ref):** [stage\_\_child\_stage](@ref), [stage\_\_output\_\_connection](@ref), [stage\_\_output\_\_node](@ref), [stage\_\_output\_\_unit](@ref) and [stage\_\_output](@ref)

>**Related [Parameters](@ref):** [stage\_scenario](@ref)


## `stage__child_stage`

> A parent-child relationship between two `stage`s (EXPERIMENTAL).

>**Related [Entity Classes](@ref):** [stage](@ref)


## `stage__output`

> An `output` that should be fixed by a `stage` for all entities in all its children (EXPERIMENTAL).

>**Related [Entity Classes](@ref):** [output](@ref) and [stage](@ref)

>**Related [Parameters](@ref):** [output\_resolution](@ref)

>**Related [parameter\_types](@ref):** [output\_resolution](@ref)


## `stage__output__connection`

> An `output` that should be fixed by a `stage` for a `connection` in all its children (EXPERIMENTAL).

>**Related [Entity Classes](@ref):** [connection](@ref), [output](@ref) and [stage](@ref)

>**Related [Parameters](@ref):** [output\_resolution](@ref) and [slack\_penalty](@ref)

>**Related [parameter\_types](@ref):** [output\_resolution](@ref)


## `stage__output__node`

> An `output` that should be fixed by a `stage` for a `node` in all its children (EXPERIMENTAL).

>**Related [Entity Classes](@ref):** [node](@ref), [output](@ref) and [stage](@ref)

>**Related [Parameters](@ref):** [output\_resolution](@ref) and [slack\_penalty](@ref)

>**Related [parameter\_types](@ref):** [output\_resolution](@ref)


## `stage__output__unit`

> An `output` that should be fixed by a `stage` for a `unit` in all its children (EXPERIMENTAL).

>**Related [Entity Classes](@ref):** [output](@ref), [stage](@ref) and [unit](@ref)

>**Related [Parameters](@ref):** [output\_resolution](@ref) and [slack\_penalty](@ref)

>**Related [parameter\_types](@ref):** [output\_resolution](@ref)


## `stochastic_scenario`

> A scenario for stochastic optimisation in SpineOpt.

>**Related [Entity Classes](@ref):** [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) and [stochastic\_structure\_\_stochastic\_scenario](@ref)

Essentially, a [stochastic\_scenario](@ref) is a label for an alternative period of time,
describing one possibility of what might come to pass.
They are the basic building blocks of the scenario-based [Stochastic Framework](@ref) in *SpineOpt.jl*,
but aren't really meaningful on their own.
Only when combined into a [stochastic\_structure](@ref) using the [stochastic\_structure\_\_stochastic\_scenario](@ref)
and [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationships,
along with [Parameters](@ref) like the [weight\_relative\_to\_parents](@ref) and [stochastic\_scenario\_end](@ref),
they become meaningful.
## `stochastic_structure`

> A group of stochastic scenarios that represent a structure.

>**Related [Entity Classes](@ref):** [connection\_\_investment\_stochastic\_structure](@ref), [model\_\_default\_investment\_stochastic\_structure](@ref), [model\_\_default\_stochastic\_structure](@ref), [node\_\_investment\_stochastic\_structure](@ref), [node\_\_stochastic\_structure](@ref), [stochastic\_structure\_\_stochastic\_scenario](@ref), [unit\_\_investment\_stochastic\_structure](@ref) and [units\_on\_\_stochastic\_structure](@ref)

The [stochastic\_structure](@ref) is the key component of the scenario-based [Stochastic Framework](@ref)
in *SpineOpt.jl*, and essentially represents a group of [stochastic\_scenario](@ref)s with set [Parameters](@ref).
The [stochastic\_structure\_\_stochastic\_scenario](@ref) relationship defines which [stochastic\_scenario](@ref)s
are included in which [stochastic\_structure](@ref)s, and the [weight\_relative\_to\_parents](@ref) and
[stochastic\_scenario\_end](@ref) [Parameters](@ref) define the exact shape and impact of the
[stochastic\_structure](@ref), along with the [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref)
relationship.

The main reason as to why [stochastic\_structure](@ref)s are so important is, that they act as handles connecting the
[Stochastic Framework](@ref) to the modelled system.
This is handled using the [Structural relationship classes](@ref) e.g. [node\_\_stochastic\_structure](@ref),
which define the [stochastic\_structure](@ref) applied to each `object` describing the modelled system.
Connecting each system `object` to the appropriate [stochastic\_structure](@ref) individually can be a bit bothersome
at times, so there are also a number of convenience [Meta relationship classes](@ref) like the
[model\_\_default\_stochastic\_structure](@ref), which allow setting [model](@ref)-wide defaults to be used whenever
specific definitions are missing.
## `stochastic_structure__stochastic_scenario`

> A `stochastic_scenarios` that belongs in a `stochastic_structure`.

>**Related [Entity Classes](@ref):** [stochastic\_scenario](@ref) and [stochastic\_structure](@ref)

>**Related [Parameters](@ref):** [stochastic\_scenario\_end](@ref) and [weight\_relative\_to\_parents](@ref)

>**Related [parameter\_types](@ref):** [stochastic\_scenario\_end](@ref) and [weight\_relative\_to\_parents](@ref)

The [stochastic\_structure\_\_stochastic\_scenario](@ref) relationship defines which [stochastic\_scenario](@ref)s
are included in which [stochastic\_structure](@ref), as well as holds the [stochastic\_scenario\_end](@ref) and
[weight\_relative\_to\_parents](@ref) [Parameters](@ref) defining how the [stochastic\_structure](@ref) interacts
with the [Temporal Framework](@ref) and the [Objective function](@ref).
Along with [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref),
this relationship is used to define the exact properties of each [stochastic\_structure](@ref),
which are then applied to the `objects` describing the modelled system according to the
[Structural relationship classes](@ref), like the [node\_\_stochastic\_structure](@ref) relationship.
## `temporal_block`

> A length of time with a particular resolution.

>**Related [Entity Classes](@ref):** [connection\_\_investment\_temporal\_block](@ref), [model\_\_default\_investment\_temporal\_block](@ref), [model\_\_default\_temporal\_block](@ref), [node\_\_investment\_temporal\_block](@ref), [node\_\_temporal\_block](@ref), [unit\_\_investment\_temporal\_block](@ref) and [units\_on\_\_temporal\_block](@ref)

>**Related [Parameters](@ref):** [block\_end](@ref), [block\_start](@ref), [has\_free\_start](@ref), [representative\_block\_index](@ref), [representative\_blocks\_by\_period](@ref), [resolution](@ref) and [weight](@ref)

>**Related [parameter\_types](@ref):** [block\_end](@ref), [block\_start](@ref), [resolution](@ref) and [weight](@ref)

A temporal block defines the temporal properties of the optimization that is to be solved in the current window. It is the key building block of the [Temporal Framework](@ref). Most importantly, it holds the necessary information about the resolution and horizon of the optimization. A single model can have multiple temporal blocks, which is one of the main sources of temporal flexibility in Spine: by linking different parts of the model to different temporal blocks, a single model can contain aspects that are solved with different temporal resolutions or time horizons.

## `unit`

> A conversion of one/many commodities between nodes.

>**Related [Entity Classes](@ref):** [node\_\_to\_unit](@ref), [stage\_\_output\_\_unit](@ref), [unit\_\_investment\_group](@ref), [unit\_\_investment\_stochastic\_structure](@ref), [unit\_\_investment\_temporal\_block](@ref), [unit\_\_to\_node](@ref), [unit\_\_user\_constraint](@ref), [units\_on\_\_stochastic\_structure](@ref) and [units\_on\_\_temporal\_block](@ref)

>**Related [Parameters](@ref):** [availability\_factor](@ref), [benders\_starting\_units\_invested](@ref), [curtailment\_cost](@ref), [decommissioning\_time](@ref), [discount\_rate\_technology\_specific](@ref), [existing\_units](@ref), [fom\_cost](@ref), [investment\_count\_fix\_cumulative](@ref), [investment\_count\_fix\_new](@ref), [investment\_count\_initial\_cumulative](@ref), [investment\_count\_initial\_new](@ref), [investment\_count\_max\_cumulative](@ref), [investment\_variable\_type](@ref), [is\_renewable](@ref), [lead\_time](@ref), [lifetime\_constraint\_sense](@ref), [lifetime\_economic](@ref), [lifetime\_technical](@ref), [mga\_investment\_active](@ref), [mga\_investment\_big\_m](@ref), [mga\_investment\_weight](@ref), [min\_down\_time](@ref), [min\_up\_time](@ref), [online\_count\_fix](@ref), [online\_count\_initial](@ref), [online\_variable\_type](@ref), [out\_of\_service\_count\_fix](@ref), [out\_of\_service\_count\_initial](@ref), [outage\_scheduled\_duration](@ref), [outage\_variable\_type](@ref), [shut\_down\_cost](@ref), [start\_up\_cost](@ref), [unit\_decommissioning\_cost](@ref), [unit\_investment\_cost](@ref), [units\_on\_cost](@ref), [units\_on\_non\_anticipativity\_margin](@ref) and [units\_on\_non\_anticipativity\_time](@ref)

>**Related [parameter\_types](@ref):** [decommissioning\_time](@ref), [investment\_variable\_type](@ref), [is\_renewable](@ref), [lead\_time](@ref), [lifetime\_constraint\_sense](@ref), [lifetime\_economic](@ref), [lifetime\_technical](@ref), [mga\_investment\_active](@ref), [min\_down\_time](@ref), [min\_up\_time](@ref), [online\_variable\_type](@ref), [outage\_variable\_type](@ref) and [units\_on\_non\_anticipativity\_time](@ref)

A [unit](@ref) represents an energy conversion process, where energy of one commodity can be converted
into energy of another commodity. For example, a gas turbine, a power plant, or even a load,
can be modelled using a [unit](@ref).

A [unit](@ref) always takes energy from one or more [node](@ref)s, and releases energy to
one or more (possibly the same) [node](@ref)s.
The former are specificed through the [node\_\_to\_unit](@ref) relationship,
and the latter through [unit\_\_to\_node](@ref).
Every [unit](@ref) has a temporal and stochastic structures given by the
[units\_on\_\_temporal\_block](@ref) and [units\_on\_\_stochastic\_structure] relationships.
The model will generate `unit_flow` variables for every combination of
[unit](@ref), [node](@ref), *direction* (from node or to node), *time slice*, and *stochastic scenario*,
according to the above relationships.

The operation of the [unit](@ref) is specified through a number of parameter values.
For example, the capacity of the unit, as the maximum amount of energy that can enter or leave it,
is given by [capacity\_per\_unit](@ref).
The conversion ratio of input to output can be specified using any of [fix\_ratio\_out\_in\_unit\_flow](@ref),
[max\_ratio\_out\_in\_unit\_flow](@ref), and [min\_ratio\_out\_in\_unit\_flow](@ref).
The variable operating cost is given by [vom\_cost](@ref).
## `unit__investment_group`

> A `unit` that belongs in an `investment_group`.

>**Related [Entity Classes](@ref):** [investment\_group](@ref) and [unit](@ref)


## `unit__investment_stochastic_structure`

> The `stochastic_structure` of a `unit` investment.

>**Related [Entity Classes](@ref):** [stochastic\_structure](@ref) and [unit](@ref)

The [unit\_\_investment\_stochastic\_structure](@ref) relationship defines the [stochastic\_structure](@ref)
of [unit](@ref)-related investment decisions.
Essentially, it sets the [stochastic\_structure](@ref) used by the [units\_invested\_available](@ref) variable of the [unit](@ref).

The [unit\_\_investment\_stochastic\_structure](@ref) relationship uses the
[model\_\_default\_investment\_stochastic\_structure](@ref) relationship if not defined.

## `unit__investment_temporal_block`

> The `temporal_block` of a `unit` investment.

>**Related [Entity Classes](@ref):** [temporal\_block](@ref) and [unit](@ref)

`unit__investment_temporal_block` is a two-dimensional relationship between a [unit](@ref) and a [temporal_block](@ref). This relationship defines the temporal resolution and scope of a unit's investment decision. Note that in a decomposed investments problem with two model objects, one for the master problem model and another for the operations problem model, the link to the specific model is made indirectly through the [model__temporal_block](@ref) relationship. If a [model\_\_default\_investment\_temporal_block](@ref) is specified and no `unit__investment_temporal_block` relationship is specified, the [model\_\_default\_investment\_temporal\_block](@ref) relationship will be used. Conversely if `unit__investment_temporal_block` is specified along with [model\_\_temporal\_block](@ref), this will override [model\_\_default\_investment\_temporal\_block](@ref) for the specified [unit](@ref).

See also [Investment Optimization](@ref)

## `unit__to_node`

> A flow on a `unit` to a `node`.

>**Related [Entity Classes](@ref):** [node](@ref) and [unit](@ref)

>**Related [Parameters](@ref):** [capacity\_per\_unit](@ref), [capacity\_to\_flow\_conversion\_factor](@ref), [fix\_nonspin\_units\_shut\_down](@ref), [fix\_nonspin\_units\_started\_up](@ref), [flow\_limits\_fix\_op](@ref), [flow\_limits\_fix](@ref), [flow\_limits\_initial\_op](@ref), [flow\_limits\_initial](@ref), [flow\_limits\_max\_cumulative](@ref), [flow\_limits\_min\_cumulative](@ref), [flow\_limits\_min](@ref), [fuel\_cost](@ref), [initial\_nonspin\_units\_shut\_down](@ref), [initial\_nonspin\_units\_started\_up](@ref), [minimum\_operating\_point](@ref), [operating\_points](@ref), [ordered\_unit\_flow\_op](@ref), [ramp\_limits\_down](@ref), [ramp\_limits\_shutdown](@ref), [ramp\_limits\_startup](@ref), [ramp\_limits\_up](@ref), [reserve\_procurement\_cost](@ref), [unit\_flow\_non\_anticipativity\_margin](@ref), [unit\_flow\_non\_anticipativity\_time](@ref) and [vom\_cost](@ref)

>**Related [parameter\_types](@ref):** [operating\_points](@ref), [ordered\_unit\_flow\_op](@ref) and [unit\_flow\_non\_anticipativity\_time](@ref)

The [unit\_\_to\_node](@ref) and [node\_\_to\_unit](@ref) unit relationships are core elements of SpineOpt.
For each [unit\_\_to\_node](@ref) or [node\_\_to\_unit](@ref), a [unit\_flow](@ref) variable is automatically
added to the model, i.e.
a commodity flow of a unit to or from a specific node, respectively.

Various parameters can be defined on the [unit\_\_to\_node](@ref) relationship, in order to
constrain the associated unit flows. In most cases a [capacity\_per\_unit](@ref) will be defined for
an upper bound on the commodity flows. Apart from that, ramping abilities of a unit can be
defined. For further details on ramps see [Ramping](@ref).

To associate costs with a certain commodity flow, cost terms, such as [fuel\_cost](@ref)s and [vom\_cost](@ref)s,
can be included for the [unit\_\_to\_node](@ref) relationship.

It is important to note, that the parameters associated with the [unit\_\_to\_node](@ref) can be defined either
for a specific [node](@ref), or for a group of nodes. Grouping nodes for the described parameters will result
in an aggregation of the unit flows for the triggered constraint, e.g. the definition of the [capacity\_per\_unit](@ref)
on a group of nodes will result in an upper bound on the sum of all individual [unit\_flow](@ref)s.

## `unit__user_constraint`

> A `unit` commitment constrained by a `user_constraint`.

>**Related [Entity Classes](@ref):** [unit](@ref) and [user\_constraint](@ref)

>**Related [Parameters](@ref):** [coefficient\_for\_units\_invested\_available](@ref), [coefficient\_for\_units\_invested](@ref), [coefficient\_for\_units\_on](@ref) and [coefficient\_for\_units\_started\_up](@ref)

`unit__user_constraint` is a two-dimensional relationship between a [unit](@ref) and a [user_constraint](@ref). The relationship specifies that a variable or variable(s) associated only with the unit (not a `unit_flow` for example) are involved in the constraint. For example, the [coefficient\_for\_units\_on](@ref) defined on `unit__user_constraint` specifies the coefficient of the [unit](@ref)'s `units_on` variable in the specified [user_constraint](@ref).

See also [user_constraint](@ref)

## `unit_flow`

> A superclass for unit__to_node and node__to_unit classes.

>**Related [Entity Classes](@ref):** [unit\_flow\_\_investment\_group](@ref), [unit\_flow\_\_unit\_flow](@ref) and [unit\_flow\_\_user\_constraint](@ref)


## `unit_flow__investment_group`

> A flow on a `unit` from/to a `node` whose capacity should be counted in the capacity invested available of an `investment_group`.

>**Related [Entity Classes](@ref):** [investment\_group](@ref) and [unit\_flow](@ref)


## `unit_flow__unit_flow`

> Two `unit_flow` entities (and variables) that are constrained by each other.

>**Related [Entity Classes](@ref):** [unit\_flow](@ref)

>**Related [Parameters](@ref):** [flow\_ratio\_equality\_coefficient](@ref), [flow\_ratio\_equality\_online\_coefficient](@ref), [flow\_ratio\_greater\_than\_coefficient](@ref), [flow\_ratio\_greater\_than\_online\_coefficient](@ref), [flow\_ratio\_less\_than\_coefficient](@ref), [flow\_ratio\_less\_than\_online\_coefficient](@ref) and [flow\_ratio\_start\_flow](@ref)


## `unit_flow__user_constraint`

> A flow on a `unit` from/to a `node` constrained by a `user_constraint`.

>**Related [Entity Classes](@ref):** [unit\_flow](@ref) and [user\_constraint](@ref)

>**Related [Parameters](@ref):** [coefficient\_for\_unit\_flow](@ref)

`unit_flow__user_constraint` is a relationship between a [unit\_flow](@ref) and a [user\_constraint](@ref). The relationship specifies that the `unit_flow` variable between the specified [unit](@ref) and the specified [node](@ref) is involved in the specified [user\_constraint](@ref). Parameters on this relationship generally apply to this specific `unit_flow` variable. For example the parameter [coefficient\_for\_unit\_flow](@ref) defined on `unit_flow__user_constraint` represents the coefficient on the specific `unit_flow` variable in the specified [user_constraint](@ref)

## `units_on__stochastic_structure`

> The `stochastic_structure` of a `unit` commitment. Only one `stochastic_structure` is permitted per `unit`.

>**Related [Entity Classes](@ref):** [stochastic\_structure](@ref) and [unit](@ref)

The [units\_on\_\_stochastic\_structure](@ref) relationship defines the [stochastic\_structure](@ref)
used by the [units\_on](@ref) variable.
Essentially, this relationship permits defining a different [stochastic\_structure](@ref) for the online decisions
regarding the [units\_on](@ref) variable,
than what is used for the production [unit\_flow](@ref) variables.
A common use-case is e.g. using only one [units\_on](@ref) variable
across multiple [stochastic\_scenario](@ref)s for the [unit\_flow](@ref) variables.
Note that only one [units\_on\_\_stochastic\_structure](@ref) relationship can be defined per [unit](@ref) per [model](@ref),
as interpreted by the [units\_on\_\_stochastic\_structure](@ref) and [model\_\_stochastic\_structure](@ref)
relationships.

The [units\_on\_\_stochastic\_structure](@ref) relationship uses the [model\_\_default\_stochastic\_structure](@ref)
relationship if not specified.
## `units_on__temporal_block`

> The `temporal_block` of a `unit` commitment.

>**Related [Entity Classes](@ref):** [temporal\_block](@ref) and [unit](@ref)

[units\_on\_\_temporal\_block](@ref) is a relationship linking the [units\_on](@ref) variable of a unit to a specific [temporal\_block](@ref) object. As such, this relationship will determine which temporal block governs the on- and offline status of the unit. The temporal block holds information on the temporal scope and resolution for which the variable should be optimized.  

## `user_constraint`

> A generic data-driven custom constraint.

>**Related [Entity Classes](@ref):** [connection\_\_from\_node\_\_user\_constraint](@ref), [connection\_\_to\_node\_\_user\_constraint](@ref), [connection\_\_user\_constraint](@ref), [node\_\_user\_constraint](@ref), [unit\_\_user\_constraint](@ref) and [unit\_flow\_\_user\_constraint](@ref)

>**Related [Parameters](@ref):** [constraint\_sense](@ref), [include\_in\_non\_representative\_periods](@ref), [right\_hand\_side](@ref) and [user\_constraint\_slack\_penalty](@ref)

>**Related [parameter\_types](@ref):** [constraint\_sense](@ref) and [include\_in\_non\_representative\_periods](@ref)

The [user\_constraint](@ref) is a generic data-driven [custom constraint](@ref constraint_user_constraint),
which allows for defining constraints involving multiple [unit](@ref)s, [node](@ref)s, or [connection](@ref)s.
The [constraint\_sense](@ref) parameter changes the sense of the [user\_constraint](@ref),
while the [right\_hand\_side](@ref) parameter allows for defining the constant terms of the constraint.

Coefficients for the different [variables](@ref Variables) appearing in the [user\_constraint](@ref) are defined
using relationships, like e.g. [unit\_flow\_\_user\_constraint](@ref) and
[connection\_\_to\_node\_\_user\_constraint](@ref) for [unit\_flow](@ref) and [connection\_flow](@ref) variables,
or [unit\_\_user\_constraint](@ref) and [node\_\_user\_constraint](@ref) for [units\_on](@ref), [units\_started\_up](@ref),
and [node_state](@ref) variables.

For more information, see the dedicated article on [User Constraints](@ref)
