# Multi-year Investments Using Economic Parameters Tutorial

The basics of how to set up a capacity planning model are covered in [Capacity Planning Tutorial](@ref) and multi-year investments in [Multi-year investments](@ref). With that information, you should be able to do multi-year investments already with your own parameters. However, the correct representation for costs across years can be tricky. To make it more user-friendly, SpineOpt has incorporated some pre-defined economic parameters internally, and the goal of this tutorial is to walk you through the set-up for using these parameters.

!!! info
    The details of the formulation and economic parameters are given in the concept references.

## Overview
In this tutorial, we will
- simplify the simple system tutorial by only using one `power_plant`,
- show the necessary parameters to activate and use pre-defined internal parameters,
- show you how to use these economic parameters,
- show you how to use milestone years. 

## Set-up
To avoid repetition, we only consider one unit instead of the two units from the simple system tutorial. The easiest way to do this is to import the [simple system](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/simple_system.json) (file > import) and to remove one of the two power plants. To remove a power plant, right-click `power_plant_b` in the Entity tree and select *Remove...*. This also removes the entities that refer to `power_plant_b` (e.g. `fuel_node | power_plant_b`) and their parameter values, but not the nodes, which we still need for `power_plant_a`. There will be a confirmation box with an overview of all the entities that you will be removing.

Since we are working with investments, we are going to make a distinction between investments and operation in the time blocks. We retain the original time block, rename it from `flat` to `operation` and adjust the resolution to 4 months ('4M'). Additionally, we add an investment time block with a resolution of 5 years ('5Y') between 2000 and 2006. We have to adjust the time horizon of the model entity accordingly. As in the [Capacity Planning Tutorial](@ref), connect the investment time block to the model with the [model\_\_default\_investment\_temporal\_block](@ref) entity, and the existing stochastic structure with the [model\_\_default\_investment\_stochastic\_structure](@ref) entity.

Once we have our setup, we can take a look at the economic representation in SpineOpt. Below is a list of parameters you would need:
- [multiyear\_economic\_discounting](@ref): activation value in a choice between `consecutive_years` and `milestone_years`, with the default value being `null` (`None` in a SpineDB and `nothing` in Julia). When a valid value is selected, the model will use its internally-calculated parameters for discounting investment and operation costs. Specifically, choosing `consecutive_years` requires the model to use continuous operational temporal blocks, and thus the operation cost will be discounted every year. In contrast, choosing `milestone_years` means the model will discount the operation cost as per the investment temporal block.  
- [discount\_rate](@ref): the rate you would like to discount your costs with.
- [discount\_year](@ref): the year you would like to discount your costs to.
- [lifetime\_technical](@ref): using units as an example, this is the technical lifetime of the unit.
- [lifetime\_economic](@ref): using units as an example, this is the economic lifetime of the unit which is used to calculate the economic parameters.
- [optional] [discount\_rate\_technology\_specific](@ref): using units as an example, this is used if you would like to have a specific discount rate different from [discount\_rate](@ref).
- [optional] [lead\_time](@ref): if not specified, the default lead time is 0. 
- [unit\_investment\_cost](@ref): using unit as an example, this is the investment cost for the investment year. When [multiyear\_economic\_discounting](@ref) is not used (i.e. with the default value `null`), then this cost that you put will not be discounted at all. However, when you choose a valid value of [multiyear\_economic\_discounting](@ref), SpineOpt will discount this cost to the [discount\_year](@ref) using [discount\_rate](@ref).

To be able to see the values of the economic parameters after a run, you have to add them to the report. 

![image](figs_multi-year/report.png)

## Not using economic discounting
We start with the case where [multiyear\_economic\_discounting](@ref) is not used with the default value `null`, which means SpineOpt will not create and use its internally-calculated parameters for discounting investment and operation costs. A [unit\_investment\_cost](@ref) of 100 and a [vom\_cost](@ref) of 25 are not discounted at all. See the set-up below (the parameter values with alternative `Base`; the values that come with the simple system are marked with *).

| Entity class | Entity | Parameter | Value |
|:---|:---|:---|:---|
| model | simple | [discount\_rate](@ref) | 0.05 |
| model | simple | [discount\_year](@ref) | 1990-01-01T00:00:00 |
| model | simple | [model\_start](@ref) | 2000-01-01T00:00:00 |
| model | simple | [model\_end](@ref) | 2006-01-01T00:00:00 |
| node | electricity\_node | [demand](@ref) | 100.0 |
| node | fuel\_node | [balance\_type](@ref) | none * |
| temporal\_block | investment | [block\_start](@ref) | 2000-01-01T00:00:00 |
| temporal\_block | investment | [block\_end](@ref) | 2006-01-01T00:00:00 |
| temporal\_block | investment | [resolution](@ref) | 5Y |
| temporal\_block | operation | [resolution](@ref) | 4M |
| unit | power\_plant\_a | [existing\_units](@ref) | 0.0 |
| unit | power\_plant\_a | [investment\_count\_max\_cumulative](@ref) | 1.0 |
| unit | power\_plant\_a | [discount\_rate\_technology\_specific](@ref) | 0.07 |
| unit | power\_plant\_a | [unit\_investment\_cost](@ref) | 100.0 |
| unit | power\_plant\_a | [lifetime\_economic](@ref) | 10Y |
| unit | power\_plant\_a | [lifetime\_technical](@ref) | 10Y |
| node\_\_to\_unit | fuel\_node ǀ power\_plant\_a | [vom\_cost](@ref) | 25.0 * |
| unit\_\_to\_node | power\_plant\_a ǀ electricity\_node | [capacity\_per\_unit](@ref) | 100.0 * |
| unit\_flow\_\_unit\_flow | power\_plant\_a ǀ electricity\_node ǀ fuel\_node ǀ power\_plant\_a | [flow\_ratio\_equality\_coefficient](@ref) | 1.0 |

Note that [existing\_units](@ref) is set to 0, since its default value is 1 and the model would otherwise not need to invest.

## Using economic parameters with consecutive operation years
Now we set [multiyear\_economic\_discounting](@ref) to `consecutive_years`. This set-up indicates that the model will use the internally-calculated parameters and continuous operational temporal blocks. Now the [unit\_investment\_cost](@ref) and the [vom\_cost](@ref) are discounted to 1990 using a [discount\_rate](@ref) of 0.05. Compared to the previous set-up, we only add one value:

| Entity class | Entity | Parameter | Value |
|:---|:---|:---|:---|
| model | simple | [multiyear\_economic\_discounting](@ref) | consecutive\_years |

The values for the output parameter `unit_discounted_duration` are shown below. It is used to discount operation costs so it has the resolution of the operational temporal block. However, since we only discount per year, this parameter value is constant within a year.

![image](figs_multi-year/unit_discounted_duration.png)

The rest is for discounting investment costs with the resolution of the investment temporal block.

![image](figs_multi-year/unit_conversion_to_discounted_annuities.png)

## Using economic parameters with milestone investment years
Now we set [multiyear\_economic\_discounting](@ref) to `milestone_years`. This indicates that we want operational temporal block to be discontinuous and use the same milestone years as the investment temporal block. In this case, we need to change the definition of temporal blocks. Compared to the previous set-up, set [multiyear\_economic\_discounting](@ref) to `milestone_years`, delete the `operation` temporal block and add two new operation temporal blocks, both connected to the model with [model\_\_default\_temporal\_block](@ref) entities (`simple | operation1` and `simple | operation2`):

| Entity class | Entity | Parameter | Value |
|:---|:---|:---|:---|
| model | simple | [multiyear\_economic\_discounting](@ref) | milestone\_years |
| temporal\_block | operation1 | [block\_start](@ref) | 2000-01-01T00:00:00 |
| temporal\_block | operation1 | [block\_end](@ref) | 2001-01-01T00:00:00 |
| temporal\_block | operation1 | [resolution](@ref) | 4M |
| temporal\_block | operation2 | [block\_start](@ref) | 2004-09-01T00:00:00 |
| temporal\_block | operation2 | [block\_end](@ref) | 2006-01-01T00:00:00 |
| temporal\_block | operation2 | [resolution](@ref) | 4M |
| node | electricity\_node | [demand](@ref) | Time series (see below) |

where the demand `TimeSeries` is defined as follows:

![image](figs_multi-year/demand_ts_milestone.png)

!!! info
    If you get confused why the temporal blocks are defined this way, I recommend going back to [Multi-year investments](@ref) for details.

The values for the output parameter `unit_discounted_duration` are shown below. Note now in 2000, the value becomes 2.79. This parameter value acts as a weight taking into account the discount per year and the resolution of the milestone years. In other words, now the operation costs for the in-between years have also been included.

![image](figs_multi-year/unit_discounted_duration_milestone.png)

The rest is for discounting investment costs with the resolution of the investment temporal block.

![image](figs_multi-year/unit_conversion_to_discounted_annuities_milestone.png)
