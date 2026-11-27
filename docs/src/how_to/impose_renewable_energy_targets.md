# How to impose renewable energy targets

This how-to shows how variable renewable energy is modelled in SpineOpt and how renewable targets and carbon policies can be imposed on a model: a lower limit on renewable generation, an upper limit on carbon emissions and a carbon tax. Each method is illustrated with a small example system, which is available as example files.

## Modelling variable renewable energy

A variable renewable energy (VRE) source, such as a wind farm or a solar park, is a [unit](@ref) with only an output flow:

1. Add the [unit](@ref), e.g. `wind_farm`, and a [unit\_\_to\_node](@ref) entity from the unit to the electricity node. The unit needs no input flow, because its 'fuel' is free.
2. Give the [unit\_\_to\_node](@ref) entity a [capacity\_per\_unit](@ref), i.e. the installed capacity.
3. Give the [unit](@ref) an [availability\_factor](@ref) as a time series of values between 0 and 1, i.e. the generation profile of the weather year. The available capacity in each time step is the [capacity\_per\_unit](@ref) multiplied by the [availability\_factor](@ref).

The unit can produce any amount up to the available capacity, so the model curtails the VRE generation automatically when it is not needed. To penalise curtailment, give the unit a [curtailment\_cost](@ref): it adds the cost of the unused available capacity to the objective function. A [vom\_cost](@ref) on the [unit\_\_to\_node](@ref) entity can be used for the operation and maintenance costs that depend on the generation.

Since VRE generation has no fuel cost, the model always uses it before other units. Therefore, a lower limit on renewable generation only affects the results when the model has to choose between renewable sources with a cost, e.g. biomass, or when it can invest in new renewable capacity.

## [Example system](@id renewable_targets_example)

The example system has an electricity node with a demand of 150, 160, 170 and 140 MW in four hourly time steps, and three units:

| unit | capacity (MW) | input | efficiency | cost (EUR/MWh of electricity) | CO2 (t/MWh of electricity) |
|:---|---:|:---|---:|---:|---:|
| *wind\_farm* | 100 | - | - | 0 | 0 |
| *gas\_plant* | 200 | *gas\_node* | 0.5 | 50 | 0.4 |
| *bio\_plant* | 30 | *biomass\_node* | 0.4 | 80 | 0 |

The system is available as the example file [renewable\_targets\_base.json](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/renewable_targets_base.json). You can import it into an empty input database, or build it yourself: set up the workflow and import the templates as in the [Simple system tutorial](@ref), and then add the entities and values below.

| class | entities |
|:---|:---|
| [node](@ref) | `electricity_node`, `gas_node`, `biomass_node`, `co2_node` |
| [unit](@ref) | `wind_farm`, `gas_plant`, `bio_plant` |
| [node\_\_to\_unit](@ref) | `gas_node ǀ gas_plant`, `biomass_node ǀ bio_plant` |
| [unit\_\_to\_node](@ref) | `wind_farm ǀ electricity_node`, `gas_plant ǀ electricity_node`, `bio_plant ǀ electricity_node`, `gas_plant ǀ co2_node` |
| [unit\_flow\_\_unit\_flow](@ref) | `gas_plant ǀ electricity_node ǀ gas_node ǀ gas_plant`, `bio_plant ǀ electricity_node ǀ biomass_node ǀ bio_plant`, `gas_plant ǀ co2_node ǀ gas_node ǀ gas_plant` |
| [report\_\_output](@ref) | `report1 ǀ unit_flow` |

The emissions are modelled as a flow from *gas\_plant* to *co2\_node*. Its [flow\_ratio\_equality\_coefficient](@ref) is the CO2 emitted per MWh of gas, 0.2 t/MWh, which is 0.4 t per MWh of electricity with the efficiency of 0.5. The fuel nodes and the CO2 node have the [balance\_type](@ref) `none`, so they can supply or receive any amount.

| class | entity byname | parameter name | value |
|:---|:---|:---|:---|
| model | simple | [model\_start](@ref) | 2000-01-01T00:00:00 |
| model | simple | [model\_end](@ref) | 2000-01-01T04:00:00 |
| temporal\_block | flat | [resolution](@ref) | 1h |
| node | electricity\_node | [demand](@ref) | time series, see below |
| node | gas\_node | [balance\_type](@ref) | none |
| node | biomass\_node | [balance\_type](@ref) | none |
| node | co2\_node | [balance\_type](@ref) | none |
| unit | wind\_farm | [availability\_factor](@ref) | time series, see below |
| node\_\_to\_unit | gas\_node ǀ gas\_plant | [vom\_cost](@ref) | 25.0 |
| node\_\_to\_unit | biomass\_node ǀ bio\_plant | [vom\_cost](@ref) | 32.0 |
| unit\_\_to\_node | wind\_farm ǀ electricity\_node | [capacity\_per\_unit](@ref) | 100.0 |
| unit\_\_to\_node | gas\_plant ǀ electricity\_node | [capacity\_per\_unit](@ref) | 200.0 |
| unit\_\_to\_node | bio\_plant ǀ electricity\_node | [capacity\_per\_unit](@ref) | 30.0 |
| unit\_flow\_\_unit\_flow | gas\_plant ǀ electricity\_node ǀ gas\_node ǀ gas\_plant | [flow\_ratio\_equality\_coefficient](@ref) | 0.5 |
| unit\_flow\_\_unit\_flow | bio\_plant ǀ electricity\_node ǀ biomass\_node ǀ bio\_plant | [flow\_ratio\_equality\_coefficient](@ref) | 0.4 |
| unit\_flow\_\_unit\_flow | gas\_plant ǀ co2\_node ǀ gas\_node ǀ gas\_plant | [flow\_ratio\_equality\_coefficient](@ref) | 0.2 |

The [vom\_cost](@ref) is paid for the fuel input, so with the efficiencies, the costs per MWh of electricity are 25 / 0.5 = 50 EUR for *gas\_plant* and 32 / 0.4 = 80 EUR for *bio\_plant*. The two time series have an hourly resolution:

| t | demand of *electricity\_node* | availability\_factor of *wind\_farm* |
|:---|---:|---:|
| 2000-01-01T00:00:00 | 150.0 | 0.8 |
| 2000-01-01T01:00:00 | 160.0 | 0.5 |
| 2000-01-01T02:00:00 | 170.0 | 0.2 |
| 2000-01-01T03:00:00 | 140.0 | 0.9 |

The [unit\_flow](@ref var_unit_flow) results to *electricity\_node* are (MW):

| unit | 00:00 | 01:00 | 02:00 | 03:00 | total (MWh) |
|:---|---:|---:|---:|---:|---:|
| *wind\_farm* | 80 | 50 | 20 | 90 | 240 |
| *gas\_plant* | 70 | 110 | 150 | 50 | 380 |
| *bio\_plant* | 0 | 0 | 0 | 0 | 0 |

*wind\_farm* produces all it can, *gas\_plant* covers the rest of the demand and the more expensive *bio\_plant* is not used. The CO2 emissions are 0.4 × 380 = 152 t. The objective value is 19000 EUR.

Each of the following methods is a change to this system. With each of them, *bio\_plant* replaces 30 MW of *gas\_plant* in every hour, so the results are:

| unit | 00:00 | 01:00 | 02:00 | 03:00 | total (MWh) |
|:---|---:|---:|---:|---:|---:|
| *wind\_farm* | 80 | 50 | 20 | 90 | 240 |
| *gas\_plant* | 40 | 80 | 120 | 20 | 260 |
| *bio\_plant* | 30 | 30 | 30 | 30 | 120 |

## Imposing a lower limit on renewable production

In energy system models, especially in investment models, it is common to impose a lower limit on the amount of electricity generated by renewable sources. In SpineOpt, this is done with the [flow\_limits\_min\_cumulative](@ref) parameter, which triggers the [constraint\_total\_cumulated\_unit\_flow](@ref constraint_total_cumulated_unit_flow). The parameter is defined on a [unit\_\_to\_node](@ref) entity, and it sets a lower bound on the sum of the flows from the unit to the node over the whole optimisation horizon.

The value is an absolute value, so make sure that its units match the ones of the [unit\_flow](@ref var_unit_flow) variable, e.g. MWh when the flows are in MW and the time steps in hours. Defining the target as a share of the demand is not yet implemented, so the share has to be converted to an absolute value by the user.

The parameter can also be defined for unit groups and node groups. With a unit group, e.g. of all renewable units, the target covers the total generation of the group. With a node group, the target covers the flows to several nodes, e.g. the electricity nodes of a region.

!!! warning
    When you define a parameter for a unit group and a node, SpineOpt also creates a flow from the group itself to the node, as if the group were an extra unit. This flow has no capacity and no cost, so the group would supply energy for free. To prevent this, set [flow\_limits\_fix](@ref) = 0 on the same entity. The target itself is not affected, as it sums the flows of the group members.

**In the example**, the renewable units *wind\_farm* and *bio\_plant* have to produce at least 360 MWh together. They form the unit group `renewables`: right-click the [unit](@ref) class, select **Add entity group...**, enter the name, move `bio_plant` and `wind_farm` to the members with **>>** and press **OK**. Then add the [unit\_\_to\_node](@ref) entity `renewables ǀ electricity_node` with the following values:

| class | entity byname | parameter name | value |
|:---|:---|:---|:---|
| unit\_\_to\_node | renewables ǀ electricity\_node | [flow\_limits\_min\_cumulative](@ref) | 360.0 |
| unit\_\_to\_node | renewables ǀ electricity\_node | [flow\_limits\_fix](@ref) | 0.0 |

*wind\_farm* already produces all it can (240 MWh), so *bio\_plant* has to produce the missing 120 MWh at its full capacity. The objective value is 22600 EUR. The model is available as the example file [renewable\_targets\_min\_renewable\_flow.json](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/renewable_targets_min_renewable_flow.json).

## Imposing an upper limit on carbon emissions

### Over the entire optimisation horizon

To impose a limit on the total carbon emissions over the entire optimisation horizon, i.e. a carbon budget, the emissions need to be modelled as flows:

1. **[node](@ref)**: a node that represents the carbon emissions, e.g. the atmosphere as a fictive CO2 node. To distinguish e.g. between regions, there can also be more than one carbon node.
2. **[unit\_\_to\_node](@ref)**: a flow from each emitting unit to the carbon node.
3. **[unit\_flow\_\_unit\_flow](@ref)** and **[flow\_ratio\_equality\_coefficient](@ref)**: the ratio of the carbon flow to another flow of the unit, e.g. the fuel input as in the example system, or the electricity output. For a full list of possible ratios, see [unit\_flow\_\_unit\_flow](@ref) and its parameters.
4. **[flow\_limits\_max\_cumulative](@ref)**: an upper limit on the sum of the flows from a unit to a node over the whole optimisation horizon, see [constraint\_total\_cumulated\_unit\_flow](@ref constraint_total_cumulated_unit_flow). It can be defined for the [unit\_\_to\_node](@ref) entity of one unit and the carbon node, or for a unit group of e.g. all conventional units and the carbon node.

**In the example**, the CO2 emissions of *gas\_plant* are limited to 104 t:

| class | entity byname | parameter name | value |
|:---|:---|:---|:---|
| unit\_\_to\_node | gas\_plant ǀ co2\_node | [flow\_limits\_max\_cumulative](@ref) | 104.0 |

This allows 104 / 0.4 = 260 MWh of gas generation, so *bio\_plant* has to produce the missing 120 MWh at its full capacity. The result is the same as with the renewable target, and the objective value is 22600 EUR. The model is available as the example file [renewable\_targets\_carbon\_cap.json](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/renewable_targets_carbon_cap.json).

### For a specific period of time (advanced method)

If the emissions should not be capped over the entire optimisation horizon, but for specific periods of time, e.g. to impose decreasing carbon caps over time, an alternative method can be used.

To illustrate this, we assume a fictitious cap of 100 for the period 2025-2030 and a cap of 50 for the period 2030-2035. In this simple example, one carbon-emitting unit `carbon_unit` has two outgoing flows, electricity and carbon.

Three nodes are required to represent this system: an `electricity` node, a `carbon_cap_1` node (with [storage\_active](@ref) = `true` and [storage\_state\_max](@ref) = 100), and a `carbon_cap_2` node (with [storage\_active](@ref) = `true` and [storage\_state\_max](@ref) = 50).

Further, we introduce the [unit\_flow\_\_unit\_flow](@ref) entities `carbon_unit ǀ carbon_cap_1 ǀ carbon_unit ǀ electricity` and `carbon_unit ǀ carbon_cap_2 ǀ carbon_unit ǀ electricity`. On these entities, we define the ratio between emissions and electricity production. In this fictitious example, we assume 0.5 units of emissions per unit of electricity.

The [flow\_ratio\_equality\_coefficient](@ref) parameter is defined as a time-varying parameter in the following way (*simplified representation of the time series*):

- [flow\_ratio\_equality\_coefficient](@ref) of `carbon_unit ǀ carbon_cap_1 ǀ carbon_unit ǀ electricity` = [2025: 0.5; 2030: 0]
- [flow\_ratio\_equality\_coefficient](@ref) of `carbon_unit ǀ carbon_cap_2 ǀ carbon_unit ǀ electricity` = [2025: 0; 2030: 0.5]

This way, the first emission cap node `carbon_cap_1` can only be "filled" during 2025-2030, while `carbon_cap_2` can only be "filled" during the second period 2030-2035.

Note that it would also be possible to have, e.g., one node with a time-varying [storage\_state\_max](@ref). However, in this case, "unused" carbon emissions in the first period of time would be available for the second period of time.

## Imposing a carbon tax

To include carbon pricing in a model, the emissions are modelled as flows to a carbon node, as for the carbon cap above. The carbon tax is then defined with the [tax\_in\_unit\_flow](@ref) parameter of the carbon node: it adds the tax for all [unit\_flow](@ref var_unit_flow)s into the node to the objective function. To distinguish e.g. between regions, there can also be more than one carbon node.

**In the example**, the carbon tax is 100 EUR/t:

| class | entity byname | parameter name | value |
|:---|:---|:---|:---|
| node | co2\_node | [tax\_in\_unit\_flow](@ref) | 100.0 |

This raises the cost of *gas\_plant* from 50 to 50 + 0.4 × 100 = 90 EUR/MWh of electricity, which is more than the 80 EUR/MWh of *bio\_plant*, so *bio\_plant* produces at its full capacity. The objective value is 33000 EUR, of which 10400 EUR is the tax on the remaining 104 t of CO2. The model is available as the example file [renewable\_targets\_carbon\_tax.json](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/renewable_targets_carbon_tax.json).
