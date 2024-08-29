# Multi-year Investments Using Pre-defined Parameters Tutorial

The basics of how to set up a capacity planning model are covered in [Capacity planning Tutorial](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/capacity_planning/) and multi-year investments in [Multi-year investments](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/capacity_planning/#Multi-year-investments). With those information, You should be able to do multi-year investments already with your own parameters. However, the correct representation for costs across years can be tricky. To make it more user-friendly, SpineOpt has incorporated some pre-defined economic parameters, and the goal of this tutorial is to walk you through the set-up for using these parameters.

## Overview


## Set-up
Below is a list of parameters you would need to set up:
- `use_economic_represention`: if set to true, it means the model will use its internally-calculated parameters for discounting investment and operation costs. The default value is `false`, we set it to `true` in this tutorial.
- `use_milestone_years`: this parameter is used to discount operation costs. If set to `false` (default), it means we use continous operational temporal blocks, and thus the operation cost will be discounted every year. Otherwise, it will be discounted using the investment temporal block.   
- `discount_rate`: the rate you would like to discount your costs.
- `discount_year`: the year you would like to discount your costs to.
- `unit_investment_tech_lifetime`: using unit as an example, this is the technical lifetime
- `unit_investment_econ_lifetime`: using unit as an example, this is the economic lifetime which is used to calculate the economic parameters
- [optional] `unit_discount_rate_technology_specific`: using unit as an example, this is used if you would like to have a specific discount rate different from `discount_rate`
- [optional] `unit_lead_time`: if not specified, the default lead time is 0. 
- `unit_investment_cost`: using unit as an example, this is the investment cost for the investment year. Suppose you set `use_economic_represention` to `false`, then this cost that you put will not be discounted at all. However, if you set it to `true`, then SpineOpt will discount this cost to the `discount_year` using `discount_rate`.

## Not using economic parameters
We start with the case if `use_economic_represention` is set to `false`, which means SpineOpt will not create and use its internally-calculated parameters for discounting investment and operation costs. Using the set-up shown in the below picture, the objective value is 1.0962010000e+08. A `unit_investment_cost` of 100 is not discouted at all.

PIC1

## Using economic parameters but not using milestone years
Now we only change `use_economic_represention` to `true` while still keep `use_milestone_years` to default (`false`). This set-up indicates that we will use the internally-calculated parameters, and continous operational temporal blocks. Now a `unit_investment_cost` of 100 is discouted to 1990 using a `discount_rate` of 0.05. The objective value becomes 6.1186124300e+07. 

If you want to see the values of the economic parameters, you can do so by adding them to the report and inspect after the run. 
PIC2 

`unit_discounted_duration` is used to discount operation costs so it has the resolution of the operational temporal block. However, since we only discount per year, this parameter value is constant within a year.
PIC3 

The rest is for investment cost with the resolution of the investment temporal block.
PIC4

info
the details of the formulation and parameters are given in XXX

## Using economic parameters and using milestone years
Now we also change `use_milestone_years` to `true`, meaning that we also want operational temporal block to be discontinous and use the same milestone years as the investment temporal block. In this case, we need to change the definition of temporal blocks, see below picture. If you get confused why the temporal blocks are defined this way, I recommend going back to [Multi-year investments](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/capacity_planning/#Multi-year-investments) for details.

