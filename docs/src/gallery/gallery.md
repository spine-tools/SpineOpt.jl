# Example gallery

## How to run the examples

To run the examples, we recommend to follow the instructions [here](@ref recommended_workflow) to set up the basic SpineToolbox workflow, loading the JSON example file in your input data store depending on the example you want to run. We recommend creating a new SpineToolbox project for each example.

## Examples

Each example has a link to the JSON file with the input data.

- [**Simple system**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/simple_system.json): Example with two nodes and units, including the relationships among them for a temporal block with duration of one day.
- [**Stochastic model**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/stochastic.json): Setup of stochastic structures for three forecast scenarios.
- [**Capacity planning**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/capacity_planning.json): This example shows the definition of investment and operational temporal blocks in SpineOpt for one target year.
- **Multi-year investment examples**: The following examples have a setup for a multi-year investment case study (e.g., for pathway planning) in a five-year time horizon with investments every five years (e.g., at the beginning and end of the time horizon) with a 4-month operational temporal block duration. Here, we have different options in SpineOpt:
  - [*Example without economic parameters calculation*](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/multi-year_investment_without_econ_discounting.json): No extra manipulation of the input data from SpineOpt ([multiyear\_economic\_discounting](@ref) not set). So, the user input data needs to account for the value of money over time according to discount rate and year.
  - [*Example with economic parameters calculation without milestone years*](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/multi-year_investment_with_econ_discounting_consecutives.json): SpineOpt internally calculates the parameters for discounting investment and operation costs given a discount rate, discount year, and lifetime information ([multiyear\_economic\_discounting](@ref) = `consecutive_years`).
  - [*Example with economic parameters calculation with milestone years*](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/multi-year_investment_with_econ_discounting_milestones.json): Since solving five years of operation might be computationally intensive, SpineOpt offers the option of having milestone years ([multiyear\_economic\_discounting](@ref) = `milestone_years`). In that case, only two years are solved in the model. Still, one represents the operation of the non-milestone years using a calculated weight, including the discounted operation costs.
- [**Reserves constraints**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/reserves.json): Extension of the simple system including operating reserve constraints.
- [**Unit commitment constraints**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/unit_commitment.json): Extension of the simple system including unit commitment constraints.
- [**Rolling horizon**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/rolling_horizon.json): This is an Example with a total time horizon of one week, an optimization window of one day, and rolling forward one day at a time.
- [**Representative periods**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/representative_periods.json): Example with representative periods for a simple case with seasonal and short-term storage nodes.
- [**Multi-stage optimisation**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/multi_stage_model_tutorial.json): The test system of the [Multi-Stage Optimisation Tutorial](@ref), in which a long-term stage model passes results to an operational model. It has two electricity nodes connected by a line and candidate PV, wind, battery and hydrogen units.
- [**Retrofitting**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/retrofitting_example_1.json): The example of [How to Model Retrofitting](@ref): an existing generator that can be either retrofitted or replaced by a new one.
- [**6-unit system**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/6_unit_system.json): A one-week system with hourly resolution and two electricity areas connected by a line. It has seven units (nuclear, CCGT, CHP, three OCGTs and wind), a battery, heat demand and CO2 and SO2 emission nodes, and includes unit commitment, start-up and shut-down costs and a user constraint linking the electricity and heat output of the CHP.
- [**Precompile**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/precompile.json): Not an example as such. SpineOpt runs this file when the package is precompiled, so that the first run of your own model starts faster. The content is identical to the capacity planning example above, so use that one as a starting point instead.

Some archived examples are also in the spine tools repository, e.g. [case study A5](https://github.com/spine-tools/spine-cs-a5).
