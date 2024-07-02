# Investment Optimization

SpineOpt offers numerous ways to optimise investment decisions energy system models and in particular, offers a number of methologogies for capturing increased detail in investment models while containing the impact on run time. The basic principles of investments will be discussed first and this will be followed by more advanced approaches.

## Key concepts for investments

### Investment Decisions
These are the investment decisions that SpineOpt currently supports. At a high level, this means that the activity of the entities in question is controlled by an investment decision variable. The current implementation supports investments in:
   - **[unit](@ref)**
   - **[connection](@ref)**
   - **[node](@ref) storage**

### Investment Variable Types
In all cases the capacity of the [unit](@ref) or [connection](@ref) or the maximum node state of a [node](@ref) is multiplied by the investment variable which may either be continuous or integer. This is determined, for units, by setting the [unit\_investment\_variable\_type](@ref) parameter accordingly. Similary, for connections and node storages the [connection\_investment\_variable\_type](@ref) and [storage\_investment\_variable\_type](@ref) are specified.

### Identiying Investment Candidate Units, Connections and Storages
The parameter [candidate\_units](@ref) represents the number of units of this type that may be invested in. [candidate\_units](@ref) determines the upper bound of the investment variable and setting this to a value greater than 0 identifies the unit as an investment candidate unit in the optimisation. If the [unit\_investment\_variable\_type](@ref) is set to `:unit_investment_variable_type_integer`, the investment variable can be interpreted as the number of discrete units that may be invested in. However, if [unit\_investment\_variable\_type](@ref) is `:unit_investment_variable_type_continuous` and the [unit\_capacity](@ref) is set to unity, the investment decision variable can then be interpreted as the capacity of the unit rather than the number of units with [candidate\_units](@ref) being the maximum capacity that can be invested in. Finally, we can invest in discrete blocks of capacity by setting [unit\_capacity](@ref) to the size of the investment capacity blocks and have [unit\_investment\_variable\_type](@ref) set to `:unit_investment_variable_type_integer` with [candidate\_units](@ref) representing the maximum number of capacity blocks that may be invested in. The key points here are:
   - The upper bound on the relevant flow variables are determined by the product of the investment variable and the [unit\_capacity](@ref) for units, [connection\_capacity](@ref) for connections or [node\_state\_cap](@ref) for storages.
   - [candidate\_units](@ref) sets the upper bound on the investment variable, [candidate\_connections](@ref) for connections and [candidate\_storages](@ref) for storages
   - [unit\_investment\_variable\_type](@ref) determines whether the investment variable is integer or continuous ([connection\_investment\_variable\_type](@ref) for connections and [storage\_investment\_variable\_type](@ref) for storages).

### Investment Costs
Investment costs are specified by setting the appropriate `*_investment\_cost` parameter. The investment cost for [unit](@ref)s are specified by setting the [unit\_investment\_cost](@ref) parameter. This is currently interpreted as the full cost over the investment period for the unit. See the section below on **investment temporal structure** for setting the investment period. If the investment period is 1 year, then the corresponding [unit\_investment\_cost](@ref) is the annualised investment cost. For connections and storages, the investment cost parameters are [connection\_investment\_cost](@ref) and [storage\_investment\_cost](@ref), respectively.

### Temporal and Stochastic Structure of Investment Decisions
SpineOpt's flexible stochastic and temporal structure extend to investments where individual investment decisions can have their own temporal and stochastic structure independent of other investment decisions and other model variables. A global temporal resolution for all investment decisions can be defined by specifying the relationship [model\_\_default\_investment\_temporal\_block](@ref). If a specific temporal resolution is required for specific investment decisions, then one can specify the following relationships:
   - [unit\_\_investment\_temporal\_block](@ref) for [unit](@ref)s,
   - [connection\_\_investment\_temporal\_block](@ref) for [connection](@ref)s, and
   - [node\_\_investment\_temporal\_block](@ref) for storages.  
    
Specifying any of the above relationships will override the corresponding [model\_\_default\_investment\_temporal\_block](@ref).

Similarly, a global stochastic structure can be defined for all investment decisions by specifying the relationship [model\_\_default\_investment\_stochastic\_structure](@ref). If a specific stochastic structure is required for specific investment decisions, then one can specifying the following relationships:
   - [unit\_\_investment\_stochastic\_structure](@ref) for [unit](@ref)s,
   - [connection\_\_investment\_stochastic\_structure](@ref) for [connection](@ref)s, and
   - [node\_\_investment\_stochastic\_structure](@ref) for storages.
Specifying any of the above relationships will override the corresponding [model\_\_default\_investment\_stochastic\_structure](@ref).

### Impact of connection investments on network characteristics

The [model](@ref) parameter [use\_connection\_intact\_flow](@ref) is available to control whether or not the impact of connection investments on the network
characteristics should be captured.
If set to `true`, then the model will use line outage distribution factors (LODF) to compute the impact of each [connection](@ref) investment over the flow across the network. Note that this introduces another variable, [connection\_intact\_flow](@ref), representing the hypothetical flow on a [connection](@ref) in case all [connection](@ref) investments were in place. Also note that the impact of each connection is captured **individually**.

## Creating an Investment Candidate Unit Example  
If we have model that is not currently set up for investments and we wish to create an investment candidate unit, we can take the following steps.
 - Create the unit object with all the relationships and parameters necessary to describe its function.
 - Ensure that the [number\_of\_units](@ref) parameter is set to zero so that the unit is unavailable unless invested in.
 - Set the [candidate\_units](@ref) parameter for the unit to 1 to specify that a maximum of 1 new unit of this type may be invested in by the model.
 - Set the [unit\_investment\_variable\_type](@ref) to `unit_investment_variable_type_integer` to specify that this is a discrete [unit](@ref) investment decision.
 - Specify the [unit\_investment\_lifetime](@ref) of the unit to, say, 1 year to specify that this is the minimum amount of time this new unit must be in existence after being invested in.
 - Specify the investment period for this [unit](@ref)'s investment decision in one of two ways:
   - Define a default investment period for all investment decisions in the model as follows:
     - create a [temporal\_block](@ref) with the appropriate [resolution](@ref) (say 1 year)
     - link this to your [model](@ref) object by creating the appropriate [model\_\_temporal\_block](@ref) relationship
     - set it as the default investment temporal block by setting [model\_\_default\_investment\_temporal\_block](@ref)
   - Or, define an investment period unique to this investment decision as follows:
     - creating a [temporal\_block](@ref) with the appropriate [resolution](@ref) (say 1 year)
     - link this to your model object by creating the appropriate [model\_\_temporal_block](@ref) relationship
     - specify this as the investment period for your [unit](@ref)'s investment decision by setting the appropriate [unit\_\_investment\_temporal\_block](@ref) relationship
- Similarly to the above, define the stochastic structure for the [unit](@ref)'s investment decision by specifying either [model\_\_default\_investment\_stochastic\_structure](@ref) or [unit\_\_investment\_stochastic\_structure](@ref)
- Specify your [unit](@ref)'s investment cost by setting the [unit\_investment\_cost](@ref) parameter. Since we have defined the investment period above as 1 year, this is therefore the [unit](@ref)'s annualised investment cost.

## Model Reference  

### Variables for investments  

| Variable Name                        | Indices        | Description                                            |
|--------------------------------------|----------------|--------------------------------------------------------|
| `units_invested_available`|`unit`, s, t| The number of invested in `unit`s that are available at a given (s, t)|
| `units_invested` | `unit`, s, t | The point-in-time investment decision corresponding to the number of `unit`s invested in at (s,t)
| `units_mothballed` | `unit`, s, t | "Instantaneous" decision variable to mothball a `unit`
| `connections_invested_available` | `connection`, s, t | The number of invested-in `connections`s that are available at a given (s, t)
| `connections_invested` | `connection`, s, t |  The point-in-time investment decision corresponding to the number of `connections`s invested in at (s,t)
| `connections_decommissioned` | `connection`, s, t | "Instantaneous" decision variable to decommission a `connection`
| `storages_invested_available` | `node`, s, t | The number of invested-in storages that are available at a given (s, t)
| `storages_invested` | `node`, s, t | The point-in-time investment decision corresponding to the number of storages invested in at (s,t)
| `storages_decommissioned` | `node`, s, t | "instantaneous" decision variable to decommission a storage

### Relationships for investments

| Relationship Name                        | Related Object Class List    | Description                             |
|------------------------------------------|------------------------------|-----------------------------------------|
| `model__default_investment_temporal_block`|`model, temporal_block`| Default temporal resolution for investment decisions effective if unit__investment_temporal_block is not specified
| `model__default_investment_stochastic_structure`|`model, stochastic_structure`| Default stochastic structure for investment decisions effective if unit__investment_stochastic_structure is not specified
| `unit__investment_temporal_block`|`unit, temporal_block`| Set temporal resolution of investment decisions - overrides model__default_investment_temporal_block
| `unit__investment_stochastic_structure`|`unit, stochastic_structure`| Set stochastic structure for investment decisions - overrides model__default_investment_stochastic_structure


### Parameters for investments

| Parameter Name                 | Object Class List            | Description                                     |
|--------------------------------|------------------------------|-------------------------------------------------|
| `candidate_units` | `unit` | The number of additional `unit`s of this type that can be invested in
| `unit_investment_cost` | `unit` | The total overnight investment cost per candidate `unit` over the model horizon
| `unit_investment_tech_lifetime` | `unit` | The investment lifetime of the `unit` - once invested-in, a `unit` must exist for at least this amount of time
| `unit_investment_variable_type` | `unit` | Whether the `units_invested_available` variable is continuous, integer or binary
| `fix_units_invested` | `unit`| Fix the value of `units_invested`
| `fix_units_invested_available` | `unit` | Fix the value of `connections_invested_available`
| `candidate_connections` | `connection` | The number of additional `connection`s of this type that can be invested in
| `connection_investment_cost` | `connection` | The total overnight investment cost per candidate `connection` over the model horizon
| `connection_investment_tech_lifetime` | `connection` | The investment lifetime of the `connection` - once invested-in, a `connection` must exist for at least this amount of time
| `connection_investment_variable_type` | `connection` | Whether the `connections_invested_available` variable is continuous, integer or binary
| `fix_connections_invested` | `connection`| Fix the value of `connections_invested`
| `fix_connections_invested_available` | `connection` | Fix the value of `connection_invested_available`
| `candidate_storages` | `node` | The number of additional storages of this type that can be invested in at `node`
| `storage_investment_cost` | `node` | The total overnight investment cost per candidate storage over the model horizon
| `storage_investment_tech_lifetime` | `node` | The investment lifetime of the storage - once invested-in, a storage must exist for at least this amount of time
| `storage_investment_variable_type` | `node` | Whether the `storages_invested_available` variable is continuous, integer or binary
| `fix_storages_invested` | `node`| Fix the value of `storages_invested`
| `fix_storages_invested_available` | `node` | Fix the value of `storages_invested_available`


### Related Model Files


| Filename                    | Relative Path     | Description                                                  |
|-----------------------------|-------------------|--------------------------------------------------------------|
| constraint_units_invested_available.jl | \constraints| constrains `units_invested_available` to be less than `candidate_units`
| constraint_units_invested_transition.jl | \constraints| defines the relationship between `units_invested_available`, `units_invested` and `units_mothballed`. Analagous to `units_on`, `units_started` and `units_shutdown`
| constraint_unit_lifetime.jl | \constraints| once a `unit` is invested-in, it must remain in existence for at least `unit_investment_tech_lifetime` - analagous to `min_up_time`.
| constraint_units_available.jl | \constraints| Enforces `units_available` is the sum of `number_of_units` and `units_invested_available`
| constraint_connections_invested_available.jl | \constraints| constrains `connections_invested_available` to be less than `candidate_connections`
| constraint_connections_invested_transition.jl | \constraints| defines the relationship between `connections_invested_available`, `connections_invested` and `connections_decommissioned`. Analagous to `units_on`, `units_started` and `units_shutdown`
| constraint_connection_lifetime.jl | \constraints| once a `connection` is invested-in, it must remain in existence for at least `connection_investment_tech_lifetime` - analagous to `min_up_time`.
| constraint_storages_invested_available.jl | \constraints| constrains `storages_invested_available` to be less than `candidate_storages`
| constraint_storages_invested_transition.jl | \constraints| defines the relationship between `storages_invested_available`, `storages_invested` and `storages_decommissioned`. Analagous to `units_on`, `units_started` and `units_shutdown`
| constraint_storage_lifetime.jl | \constraints| once a storage is invested-in, it must remain in existence for at least `storage_investment_tech_lifetime` - analagous to `min_up_time`.
