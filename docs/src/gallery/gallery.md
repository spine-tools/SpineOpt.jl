# How to run the examples

To run the examples, we recommend to follow the instructions [here](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/simple_system/#Spine-Toolbox-workflow) to set up the basic SpineToolbox workflow. Then, follow the following steps to load the example:
- Select the *input* data store and in the *Data Store Properties* window:\
	`Dialect: sqlite`\
	`New Spine db` (button bottom left)\
	`Save` - SpineToolbox will default to a location
- Double click on *input* to open the DB Editor
- Select `File` > `Import` > Choose the JSON file corresponding to the example
- Commit the changes to the database

Remember to create your *output* data store, and you will be ready to run the examples.

# Examples

Each example has a link to the JSON file with the input data, which you can load as described before.

- [**Simple system**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/simple_system.json): Example with two nodes and units, including the relationships among them for a temporal block with duration of one day.
- [**Stochastic model**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/stochastic.json): Setup of stochastic structures for three forecast scenarios.
- [**Capacity planning**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/capacity_planning.json): This example shows the definition of investment and operational temporal blocks in SpineOpt for one target year.
- **Multi-year investment examples**: The following examples have a setup for a multi-year investment case study (e.g., for pathway planning) in a five-year time horizon with investments every five years (e.g., at the beginning and end of the time horizon) with a 4-month operational temporal block duration. Here, we have different options in SpineOpt:
  - [*Example without economic parameters calculation*](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/multi-year_investment_without_econ_params.json): No extra manipulation of the input data from SpineOpt (`use_economic_represention=false`). So, the user input data needs to account for the value of money over time according to discount rate and year.
  - [*Example with economic parameters calculation without milestone years*](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/multi-year_investment_with_econ_params_without_milestones.json): SpineOpt internally-calculates the parameters for discounting investment and operation costs given a discount rate, discount year, and lifetime information (`use_economic_represention=true`).
  - [*Example with economic parameters calculation with milestone years*](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/multi-year_investment_with_econ_params_with_milestones.json): Since solving five years of operation might be computational intensive, SpineOpt offers the option of having milestone years (`use_milestone_years=true`). In that case, only two years are solved in the model. Still, one represents the operation of the non-milestone years using a calculated weight, including the discounted operation costs.
- [**Reserves constraints**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/reserves.json): Extension of the simple system including operating reserve constraints.
- [**Unit commitment constraints**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/unit_commitment.json): Extension of the sinple system including unit commitment constraints.
- [**Rolling horizon**](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/rolling_horizon.json): This is an Example with a total time horizon of one week, an optimization window of one day, and rolling forward one day at a time. 

Some archived examples are also in the spine tools repository, e.g. [case study A5](https://github.com/spine-tools/spine-cs-a5).
