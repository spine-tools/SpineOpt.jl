# Multi-year investments tutorial

This tutorial provides a guide to model multi-year investments in a simple energy system with Spine Toolbox for SpineOpt.

## Introduction

Welcome to our tutorial, where we will walk you through the process of modeling multi-year investments in SpineOpt using Spine Toolbox. To get the most out of this tutorial, we suggest first completing the Simple System tutorial, which can be found [here](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/simple_system/).

Multi-year investments refer to making investment decisions at different points in time, such that a pathway of investments can be modeled. This is particularly useful when long-term scenarios are modeled, but modeling each year is not practical. Or in a business case, investment decisions are supposed to be made in different years which has an impact on the cash flow.

In this tutorial, we consider two investment points, at the start of the modeling horizon (2030), and 5 years later (2035). Operation is assumed to be monthly, but only in 2030 and 2035. In other words, we only model 2030 and 2035 as milestone years for the pathway 2030 - 2035.   

The additions to the simple system tutorial is that:

- investment possibilities to power plants
- economic parameters (e.g., discounting)
- 


## Common things

Remember that our previously built simple system concerns only operation without any investments, now we need to add investment possibilities. The general steps for creating a candidate unit can be found [here](https://spine-tools.github.io/SpineOpt.jl/latest/advanced_concepts/investment_optimization/). In this tutorial, we will emphasize some important set ups.

### Defining the model horizon

As mentioned, we want to model 2030 and 2035, so the model horizon needs to be changed as follows.

PIC1

### Defining the investment temporal block
Specify the investment period for this [unit](@ref)'s investment decision in one of two ways:
- Define a default investment period for all investment decisions in the model as follows:
    - create a [temporal\_block](@ref) with the appropriate [resolution](@ref) (say 1 year)
    - link this to your [model](@ref) object by creating the appropriate [model\_\_temporal\_block](@ref) relationship
    - set it as the default investment temporal block by setting [model\_\_default\_investment\_temporal\_block](@ref)
- Or, define an investment period unique to this investment decision as follows:
    - creating a [temporal\_block](@ref) with the appropriate [resolution](@ref) (say 1 year)
    - link this to your model object by creating the appropriate [model\_\_temporal_block](@ref) relationship
    - specify this as the investment period for your [unit](@ref)'s investment decision by setting the appropriate [unit\_\_investment\_temporal\_block](@ref) relationship

Here we adopt the first approach. In Spine DB Editor, we first go to **temporal block** located on the left of editor, under **Entity tree**, right-click to add an entity called **investment_block**. Then set the parameters for this block. Then add two operational blocks and set the parameters. The setups for these blocks are shown in the below picture.

PIC2.

Note
Very important to mention that at the beginning of the second operational block, we start at 2033-12-01 which is 1 time slice before the actual start date we want (i.e., 2034-01-01). This is because SpineOpt needs this extra time slice to correctly generate the constraints for the first time slice of the second operational block. In fact, if the operational blocks are non-consecutive, we need to do it for every operational blocks, except for the first one. This additional definition means that we will also have results for it, which is redundant and should be ignored when post-processing. If the operational blocks are consecutive, we would not need this.

Note 
it is important to delete the temporal blocks that are not used, and only leave the used ones. Otherwise, the temporal structure may be wrong.

PIC3 

At last, link the temporal blocks to the corresponding relationships, like the following.

PIC4

 
 ### Creating candidate_units

 Let us now move on to the definition of candidate_units

 - Ensure that the [number\_of\_units](@ref) parameter is set to zero so that the unit is unavailable unless invested in for both power plants.
 - Set the [unit\_investment\_variable\_type](@ref) to `unit_investment_variable_type_integer` to specify that this is a discrete [unit](@ref) investment decision.
 - Set the [candidate\_units](@ref) parameter to specify that the maximum number of new unit of this type may be invested in by the model.
    - We will allow investments for power_plant_a in both 2030 and 2035, and for power_plant_b only in 2035. 
    - This is realised through the definition of [candidate\_units](@ref). We define a time-varying [candidate\_units](@ref):
        - power_plant_a: [2030: 1, 2035: 2]. Note this means in 2030, 1 unit can be invested, and in 2035, another 1 **(instead of 2)** can invested. In other words, this parameter includes the previously available units.
        - power_plant_b: [2030: 0, 2035: 1]
        
        PIC5    

 - Specify the [unit\_investment\_tech\_lifetime](@ref) of the unit to, 10 year to specify that this is the minimum amount of time this new unit must be in existence after being invested in.

### Adding demands

Next, we should add demand data for the operational blocks, i.e., for every month in 2030 and 2035.

### Providing investment costs
- Specify your [unit](@ref)'s investment cost by setting the [unit\_investment\_cost](@ref) parameter. Since we have defined the investment period above as 1 year, this is therefore the [unit](@ref)'s annualised investment cost.

