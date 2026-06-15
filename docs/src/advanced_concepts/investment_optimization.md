# Investment Optimization

SpineOpt offers numerous ways to optimise investment decisions energy system models and in particular, offers a number of methodologies for capturing increased detail in investment models while containing the impact on run time. The basic principles of investments will be discussed first and this will be followed by more advanced approaches.

## Key concepts for investments

### Investment Decisions
These are the investment decisions that SpineOpt currently supports. At a high level, this means that the activity of the entities in question is controlled by an investment decision variable. The current implementation supports investments in:
   - **[unit](@ref)**
   - **[connection](@ref)**
   - **[node](@ref) storage**

### Investment Variable Types
In all cases the capacity of the [unit](@ref) or [connection](@ref) or the maximum node state of a [node](@ref) is multiplied by the investment variable which may `none`, `linear`, `integer` or `binary`. This is determined, for units and connections, by setting the [investment\_variable\_type](@ref) parameter accordingly. Similarly, for node storages the [storage\_investment\_variable\_type](@ref) is specified.

### Identiying Investment Candidate Units, Connections and Storages
The parameter [investment\_count\_max\_cumulative](@ref) represents the number of units of this type that may be invested in. [investment\_count\_max\_cumulative](@ref) determines the upper bound of the investment variable and setting this to a value greater than 0 together with setting [investment\_variable\_type](@ref) to something else than `none` identifies the unit as an investment candidate unit in the optimisation. If the [investment\_variable\_type](@ref) is set to `integer`, the investment variable can be interpreted as the number of discrete units that may be invested in. If the [investment\_variable\_type](@ref) is set to `binary`, the number of discrete unit investments is limited to 1. However, if [investment\_variable\_type](@ref) is `linear` and the [capacity\_per\_unit](@ref) is set to unity, the investment decision variable can then be interpreted as the capacity of the unit rather than the number of units with [investment\_count\_max\_cumulative](@ref) being the maximum capacity that can be invested in. Finally, we can invest in discrete blocks of capacity by setting [capacity\_per\_unit](@ref) to the size of the investment capacity blocks and have [investment\_variable\_type](@ref) set to `integer` with [investment\_count\_max\_cumulative](@ref) representing the maximum number of capacity blocks that may be invested in. The key points here are:
   - The upper bound on the relevant flow variables are determined by the product of the investment variable and the [capacity\_per\_unit](@ref) for units, [capacity\_per\_connection](@ref) for connections or [storage\_state\_max](@ref) for storages.
   - The upper bound on the investment variable is set by [investment\_count\_max\_cumulative](@ref) for units and connections and by [storage\_investment\_count\_max\_cumulative](@ref) for storages. [investment\_variable\_type](@ref) `binary` limits the upper bound to 1.
   - Whether the investment variable is binary, integer, linear or none is determined by [investment\_variable\_type](@ref) for units and connections and by [storage\_investment\_variable\_type](@ref) for storages.

### Investment Costs
Investment costs are specified by setting the appropriate `*_investment\_cost` parameter. The investment costs for [unit](@ref)s are specified by setting the [unit\_investment\_cost](@ref) parameter. This is currently interpreted as the full cost over the investment period for the unit. See the section below on **investment temporal structure** for setting the investment period. If the investment period is 1 year, then the corresponding [unit\_investment\_cost](@ref) is the annualised investment cost. For connections and storages, the investment cost parameters are [connection\_investment\_cost](@ref) and [storage\_investment\_cost](@ref), respectively.

### Temporal and Stochastic Structure of Investment Decisions
SpineOpt's flexible stochastic and temporal structure extend to investments where individual investment decisions can have their own temporal and stochastic structure independent of other investment decisions and other model variables. A global temporal resolution for all investment decisions can be defined by specifying the relationship [model\_\_default\_investment\_temporal\_block](@ref). If a specific temporal resolution is required for specific investment decisions, then one can specify the following relationships:
   - [unit\_\_investment\_temporal\_block](@ref) for [unit](@ref)s,
   - [connection\_\_investment\_temporal\_block](@ref) for [connection](@ref)s, and
   - [node\_\_investment\_temporal\_block](@ref) for storages.  
    
Specifying any of the above relationships will override the corresponding [model\_\_default\_investment\_temporal\_block](@ref).

Similarly, a global stochastic structure can be defined for all investment decisions by specifying the relationship [model\_\_default\_investment\_stochastic\_structure](@ref). If a specific stochastic structure is required for specific investment decisions, then one can specify the following relationships:
   - [unit\_\_investment\_stochastic\_structure](@ref) for [unit](@ref)s,
   - [connection\_\_investment\_stochastic\_structure](@ref) for [connection](@ref)s, and
   - [node\_\_investment\_stochastic\_structure](@ref) for storages.
Specifying any of the above relationships will override the corresponding [model\_\_default\_investment\_stochastic\_structure](@ref).

### Impact of connection investments on network characteristics

The [model](@ref) parameter [connection\_investment\_power\_flow\_impact\_active](@ref) is available to control whether the impact of connection investments on the network
characteristics should be captured.
If set to `true`, then the model will use line outage distribution factors (LODF) to compute the impact of each [connection](@ref) investment over the flow across the network. Note that this introduces another variable, [connection\_intact\_flow](@ref var_connection_intact_flow), representing the hypothetical flow on a [connection](@ref) in case all [connection](@ref) investments were in place. Also note that the impact of each connection is captured **individually**.

## Creating an Investment Candidate Unit Example  
If we have model that is not currently set up for investments, and we wish to create an investment candidate unit, we can take the following steps.
 - Create the unit object with all the relationships and parameters necessary to describe its function.
 - Ensure that the [existing\_units](@ref) parameter is set to zero so that the unit is unavailable unless invested in.
 - Set the [investment\_count\_max\_cumulative](@ref) parameter for the unit to 1 to specify that a maximum of 1 new unit of this type may be invested in by the model.
 - Set the [investment\_variable\_type](@ref) to `integer` to specify that this is a discrete [unit](@ref) investment decision.
 - Specify the [lifetime\_technical](@ref) of the unit to, say, 1 year to specify that this is the minimum amount of time this new unit must be in existence after being invested in.
 - Specify the investment period for this [unit](@ref)'s investment decision in one of two ways:
   - Define a default investment period for all investment decisions in the model as follows:
     - create a [temporal\_block](@ref) with the appropriate [resolution](@ref) (say 1 year)
     - set it as the default investment temporal block by setting [model\_\_default\_investment\_temporal\_block](@ref)
   - Or, define an investment period unique to this investment decision as follows:
     - creating a [temporal\_block](@ref) with the appropriate [resolution](@ref) (say 1 year)
     - specify this as the investment period for your [unit](@ref)'s investment decision by setting the appropriate [unit\_\_investment\_temporal\_block](@ref) relationship
- Similarly to the above, define the stochastic structure for the [unit](@ref)'s investment decision by specifying either [model\_\_default\_investment\_stochastic\_structure](@ref) or [unit\_\_investment\_stochastic\_structure](@ref)
- Specify your [unit](@ref)'s investment cost by setting the [unit\_investment\_cost](@ref) parameter. Since we have defined the investment period above as 1 year, this is therefore the [unit](@ref)'s annualised investment cost.

## Model Reference  

### Variables for investments  

| Variable Name                        | Indices        | Description                                            |
|--------------------------------------|----------------|--------------------------------------------------------|
| [units\_invested\_available](@ref var_units_invested_available)|[unit](@ref), s, t| The number of invested in [unit](@ref)s that are available at a given (s, t)|
| [units\_invested](@ref var_units_invested) | [unit](@ref), s, t | The point-in-time investment decision corresponding to the number of [unit](@ref)s invested in at (s,t)
| [units\_mothballed](@ref var_units_mothballed) | [unit](@ref), s, t | "Instantaneous" decision variable to mothball a [unit](@ref)
| [connections\_invested\_available](@ref var_connections_invested_available) | [connection](@ref), s, t | The number of invested-in [connection](@ref)s that are available at a given (s, t)
| [connections\_invested](@ref var_connections_invested) | [connection](@ref), s, t |  The point-in-time investment decision corresponding to the number of [connection](@ref)s invested in at (s,t)
| [connections\_decommissioned](@ref var_connections_decommissioned) | [connection](@ref), s, t | "Instantaneous" decision variable to decommission a [connection](@ref)
| [storages\_invested\_available](@ref var_connections_invested_available) | [node](@ref), s, t | The number of invested-in storages that are available at a given (s, t)
| [storages\_invested](@ref var_storages_invested) | [node](@ref), s, t | The point-in-time investment decision corresponding to the number of storages invested in at (s,t)
| [storages\_decommissioned](@ref var_storages_decommissioned) | [node](@ref), s, t | "instantaneous" decision variable to decommission a storage

### Relationships for investments

| Relationship Name                        | Related Object Class List    | Description                             |
|------------------------------------------|------------------------------|-----------------------------------------|
| [model\_\_default\_investment\_temporal\_block](@ref)|[model](@ref), [temporal\_block](@ref)| Default temporal resolution for investment decisions effective if [unit\_\_investment\_temporal\_block](@ref) is not specified
| [model\_\_default\_investment\_stochastic\_structure](@ref)|[model](@ref), [stochastic\_structure](@ref)| Default stochastic structure for investment decisions effective if unit__investment_stochastic_structure is not specified
| [unit\_\_investment\_temporal\_block](@ref)|[unit](@ref), [temporal\_block](@ref)| Set temporal resolution of investment decisions - overrides [model\_\_default\_investment\_temporal\_block](@ref)
| [unit\_\_investment\_stochastic\_structure](@ref)|[unit](@ref), [stochastic\_structure](@ref)| Set stochastic structure for investment decisions - overrides [model\_\_default\_investment\_stochastic\_structure](@ref)


### Parameters for investments

| Parameter Name                 | Object Class List            | Description                                     |
|--------------------------------|------------------------------|-------------------------------------------------|
| [investment\_count\_max\_cumulative](@ref) | [unit](@ref) | The number of additional [unit](@ref)s of this type that can be invested in
| [unit\_investment\_cost](@ref) | [unit](@ref) | The total overnight investment cost per candidate [unit](@ref) over the model horizon
| [lifetime\_technical](@ref) | [unit](@ref) | The investment lifetime of the [unit](@ref) - once invested-in, a [unit](@ref) must exist for at least this amount of time
| [investment\_variable\_type](@ref) | [unit](@ref) | Whether the [units\_invested\_available](@ref var_units_invested_available) variable is linear, integer or binary
| [investment\_count\_fix\_new](@ref) | [unit](@ref)| Fix the value of [units\_invested](@ref var_units_invested)
| [investment\_count\_fix\_cumulative](@ref) | [unit](@ref) | Fix the value of [units\_invested\_available](@ref var_units_invested_available)
| [investment\_count\_max\_cumulative](@ref) | [connection](@ref) | The number of additional [connection](@ref)s of this type that can be invested in
| [connection\_investment\_cost](@ref) | [connection](@ref) | The total overnight investment cost per candidate [connection](@ref) over the model horizon
| [lifetime\_technical](@ref) | [connection](@ref) | The investment lifetime of the [connection](@ref) - once invested-in, a [connection](@ref) must exist for at least this amount of time
| [investment\_variable\_type](@ref) | [connection](@ref) | Whether the [connections\_invested\_available](@ref var_connections_invested_available) variable is linear, integer or binary
| [investment\_count\_fix\_new](@ref) | [connection](@ref)| Fix the value of [connections\_invested](@ref var_connections_invested)
| [investment\_count\_fix\_cumulative](@ref) | [connection](@ref) | Fix the value of `connection_invested_available`
| [storage\_investment\_count\_max\_cumulative](@ref) | [node](@ref) | The number of additional storages of this type that can be invested in at [node](@ref)
| [storage\_investment\_cost](@ref) | [node](@ref) | The total overnight investment cost per candidate storage over the model horizon
| [storage\_lifetime\_technical](@ref) | [node](@ref) | The investment lifetime of the storage - once invested-in, a storage must exist for at least this amount of time
| [storage\_investment\_variable\_type](@ref) | [node](@ref) | Whether the [storages\_invested\_available](@ref var_connections_invested_available) variable is linear, integer or binary
| [storage\_investment\_count\_fix\_new](@ref) | [node](@ref)| Fix the value of [storages\_invested](@ref var_storages_invested)
| [storage\_investment\_count\_fix\_cumulative](@ref) | [node](@ref) | Fix the value of [storages\_invested\_available](@ref var_connections_invested_available)


### Related Model Files


| Filename                    | Relative Path     | Description                                                  |
|-----------------------------|-------------------|--------------------------------------------------------------|
| constraint_units_invested_available.jl | \constraints| constrains [units\_invested\_available](@ref var_units_invested_available) to be less than [investment\_count\_max\_cumulative](@ref)
| constraint_units_invested_transition.jl | \constraints| defines the relationship between [units\_invested\_available](@ref var_units_invested_available), [units\_invested](@ref var_units_invested) and [units\_mothballed](@ref var_units_mothballed). Analogous to [units\_on](@ref var_units_on)(@ref var_units_on), [units\_started\_up](@ref var_units_started_up) and [units\_shut\_down](@ref var_units_shut_down)
| constraint_unit_lifetime.jl | \constraints| once a [unit](@ref) is invested-in, it must remain in existence for at least [lifetime\_technical](@ref) - analogous to [min\_up\_time](@ref).
| constraint_units_available.jl | \constraints| Enforces `units_available` is the sum of [existing\_units](@ref) and [units\_invested\_available](@ref var_units_invested_available)
| constraint_connections_invested_available.jl | \constraints| constrains [connections\_invested\_available](@ref var_connections_invested_available) to be less than [investment\_count\_max\_cumulative](@ref)
| constraint_connections_invested_transition.jl | \constraints| defines the relationship between [connections\_invested\_available](@ref var_connections_invested_available), [connections\_invested](@ref var_connections_invested) and [connections\_decommissioned](@ref var_connections_decommissioned). Analogous to [units\_on](@ref var_units_on)(@ref var_units_on), [units\_started\_up](@ref var_units_started_up) and [units\_shut\_down](@ref var_units_shut_down)
| constraint_connection_lifetime.jl | \constraints| once a [connection](@ref) is invested-in, it must remain in existence for at least [lifetime\_technical](@ref) - analogous to [min\_up\_time](@ref).
| constraint_storages_invested_available.jl | \constraints| constrains [storages\_invested\_available](@ref var_connections_invested_available) to be less than [storage\_investment\_count\_max\_cumulative](@ref)
| constraint_storages_invested_transition.jl | \constraints| defines the relationship between [storages\_invested\_available](@ref var_connections_invested_available), [storages\_invested](@ref var_storages_invested) and [storages\_decommissioned](@ref var_storages_decommissioned). Analogous to [units\_on](@ref var_units_on)(@ref var_units_on), [units\_started\_up](@ref var_units_started_up) and [units\_shut\_down](@ref var_units_shut_down)
| constraint_storage_lifetime.jl | \constraints| once a storage is invested-in, it must remain in existence for at least [storage\_lifetime\_technical](@ref) - analogous to [min\_up\_time](@ref).
