# Multi-year Investments Using Pre-defined Parameters Tutorial

The basics of how to set up a capacity planning model are covered in [Capacity planning Tutorial](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/capacity_planning/) and multi-year investments in [Multi-year investments](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/capacity_planning/#Multi-year-investments). With those information, You should be able to do multi-year investments already with your own parameters. However, the correct representation for costs across years can be tricky. To make it more user-friendly, SpineOpt has incorporated some pre-defined economic parameters, and the goal of this tutorial is to walk you through the set-up for using these parameters.

## Set-up
Below is a list of parameters you would need to set up:
- `use_economic_represention`: if set to true, it means the model will use its internally-calculated parameters for discounting investment and operation costs. The default value is `false`, we set it to `true` in this tutorial.
- `use_milestone_years`: this parameter is used to discount operation costs. If set to `false` (default), it means we use continous operational temporal blocks, and thus the operation cost will be discounted every year. Otherwise,  

