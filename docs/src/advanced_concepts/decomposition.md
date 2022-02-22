# Decomposition

Decomposition approaches take advantage of certain problem structures to separate them into multiple related problems which are each more easily solved. Decomposition also allows us to do the inverse, which is to combine independent problems into a single problem, where each can be solved separately but with communication between them (e.g. investments and operations problems)

Decomposition thus allows us to do a number of things

  - Solve larger problems which are otherwise intractable
  - Include more detail in problems which otherwise need to be simplified
  - Combine related problems (e.g. investments/operations) in a more scientific way (rather than ad-hoc).
  - Employ parallel computing methods to solve multiple problems simultaneously.

## High-level Decomposition Algorithm
The high-level algorithm is described below. For a more detailed description please see [Benders decomposition](@ref benders_decomposition)

 - Model initialisation (preprocess_data_structure, generate temporal structures etc.)
 - For each benders_iteration
   - Solve master problem
   - Process master-problem solution:
     - set `units_invested_bi(unit=u, benders_iteration=bi)` equal to a timeseries representing the investment variables solution from the master problem
   - Rewind and update operations problem
   - Solve operations problem loop
   - Process operations sub-problem
     - set `units_available_mv(unit=u, benders_iteration=bi)` equal to a timeseries representing the marginal value of the units_on bound constraint
   - Test for convergence
   - Update master problem
     - Add [Benders cuts constraints](@ref constraint_mp_any_invested_cuts)
   - Next benders iteration

## Duals calculation for decomposition
The `optimize_model!()` function has been updated to optionally include an additional step for the calculation of duals. The dual solution to a MIP problem is not well defined. The standard approach to obtaining marginal values from a MIP model is to relax the integer variables, fix them to their last solution value and re-solve the problem as an LP. This is the standard approach in energy system modelling to obtain energy prices. However, although this is the standard approach, it does need to be used with caution (see here for example). The main hazard associated with inferring duals in this way is that the impact on costs of an investment may be overstated. However, since these duals are used in Benders decomposition to obtain a lower bound on costs (i.e. the maximum potential value from an investment), this is ok and can be "corrected" in the next iteration. And finally, the benders gap will tell us how close our decomposed problem is to the optimal global solution.

This additional relaxed LP solve is done as follows:

  - `add_variable!()` stores the list of integer and binary variables in `m.ext[:integer_variables]`
  - the `fix_value` for integer variables is set to the last MIP solution value
  - the integer constraints on the integer variables are `unset()`
  - A final LP is solved
  - required dual values are saved
  - integer constraints on integer variables are `set()`

This final fixed LP solve is trigged by specifying `calculate_duals=true` in the call to `optimize_model!()`

## Reporting dual values:

To report the dual of a constraint, one can add an output item with the corresponding constraint name (e.g. `constraint_nodal_balance`) and add that to a report. This will cause the corresponding constraint's relaxed problem marginal value will be reported in the output DB. When adding a constraint name as an output we need to preface the actual constraint name with `constraint_` to avoid ambiguity with variable names (e.g. `units_available`). So to report the marginal value of `units_available` we add an output object called `constraint_units_available`.

To report the `reduced_cost()` for a variable which is the marginal value of the associated active bound or fix constraints
on that variable, one can add an output object with the variable name prepended by `bound_`. So, to report the units_on reduced_cost value, one would create an output item called `bound_units_on`. If added to a report, this will cause the reduced cost of units_on in the final fixed LP to be written to the output db.
Finally, if any constraint duals or reduced_cost values are requested via a report, calculate_duals is set to true and the final fixed LP solve is triggered.

## Using Decomposition
The decomposition framework creates a master problem where the investment variables are optimised. The decomposition framework is invoked when a model object with the parameter [model\_type](@ref) set to `:spineopt_benders_operations` is found and a second model object with `model_type` set to `:spineopt_master`. Once these conditions are met, all investment decisions in the model are automatically decomposed and optimised in the master problem. This behaviour may change in the future to allow some investment decisions to be optimised in the operations problem and some optimised in the master problem as desired.

**Steps to involke decomposition in an investments problem**  
Assuming one has set up a conventional investments problem as described in [Investment Optimization](@ref) the following additional steps are required to utilise the decomposition framework:
  - Create a new [model](@ref) object to representent the benders master problem
  - Set the [model\_type](@ref) parameter for the master problem model to `spineopt_master`.
  - Set the [model\_type](@ref) parameter for the existing conventional, operations problem model to `spineopt_operations`.
  - Specify the master problem [model](@ref) parameter, `max_gap` - This determines the master problem convergence criterion for the relative benders gap. A value of 0.05 will represent a relative benders gap of 5%.
  - Specify the master problem [model](@ref) parameter `max_iterations` - This determines the master problem convergence criterion for the number of iterations. A value of 10 could be appropriate but this is highly dependent on the size and nature of the problem
  - Specify appropriate `model_report` relationships to determine which reports are written for which model
