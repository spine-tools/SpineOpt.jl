# Managing Output Data

Once a model is created and successfully run, it will hopefull produce results and output data. This section covers how the writing of output data is controlled and managed.

## Specifying Your Output Data Store
In your workflow (more more details see [Setting up a workflow for SpineOpt in Spine Toolbox](@ref) you will normally have a output datastore connected to your RunSpineOpt workflow tool. This is where your output data will be written. If no output datastore is specified, the results will be written by default to the input datastore. However, it is generally preferable to define a separate output data store for results. See [Setting up a workflow for SpineOpt in Spine Toolbox](@ref) for the steps to add an output datastore to your workflow)

## Specifying Outputs to Write
Outputting of results to the output datastore is controlled using the [output](@ref) and [report](@ref) object classes. To output a specific variable to the output datastore, we need to create an [output](@ref) object of the same name. For example, to output the `unit_flow` variable, we must create an [output](@ref) object named `unit_flow`. The SpineOpt template contains output objects for most problem variables and importing or re-importing the SpineOpt template will add these to your input datastore. So it is probable these output objects will exist already in your input datastore. Once the output objects exist in your model, they must then be added to a report object by creating an [report\_\_output](@ref) relationship

## Creating Reports
[Report](@ref)s are essentially a collection of outputs that can be written to an output datastore. Any number of report objects can be created. We add output items to a report by creating [report\_\_output](@ref) relationships between the output objects we want included and the desired report object. Finally, to write a specic report to the output database, we must create a [model\_\_report](@ref) relationship for each report object we want included in the output datastore.

## Reporting of Dual Values
To report the dual of a constraint, one can add an output item with the corresponding constraint name (e.g. `constraint_nodal_balance`) and add that to a report. This will cause the corresponding constraint's marginal value to be reported in the output DB. When adding a constraint name as an output we need to preface the actual constraint name with `constraint_` to avoid ambiguity with variable names (e.g. `units_available`). So to report the marginal value of `units_available` we add an output object called `constraint_units_available`.

To report the `reduced_cost()` for a variable which is the marginal value of the associated active bound or fix constraints
on that variable, one can add an output object with the variable name prepended by `bound_`. So, to report the units_on reduced_cost value, one would create an output item called `bound_units_on`. If added to a report, this will cause the reduced cost of units_on in the final fixed LP to be written to the output db.
Finally, if any constraint duals or reduced_cost values are requested via a report, calculate_duals is set to true and the final fixed LP solve is triggered.

## Output Writing Summary
 - We need an output object in our intput datastore for each variable or marginal value we want included in a report
 - We need to create a report object to contain our desired outputs which are added to our report via [report\_\_output](@ref) relationships
 - We need to create a [model\_\_report](@ref) object to write a specific report to the output datastore.