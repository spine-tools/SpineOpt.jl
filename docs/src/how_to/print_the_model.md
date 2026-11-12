# How to print the model

As the SpineOpt model formulation is quite complex and can change depending on a few parameters (some parts of the formulation can be activated or deactivated), it can be useful to print the model that SpineOpt sends to JuMP. There are a few ways to do this.

The model that SpineOpt sends to JuMP can be saved to a file. It is not the nicest file to read but at the very least you can find the used variables and parameter values.

To write that file you need to set the `write_mps_file` parameter of the model object to `write_mps_always`.

SpineOpt will write the file to the working directory. If you are using Spine Toolbox that working directory will be the Spine Toolbox work folder which is typically in your user directory e.g. C:\\Users\\username\\.spinetoolbox\\work\\run\_spineopt\_gibberish\_toolbox\\model\_diagnostics.mps

An alternative approach is to directly use the [`write_model_file(m;file_name)`](https://github.com/spine-tools/SpineOpt.jl/blob/master/src/util/write_information_files.jl) function, where `m` is a reference to your model and `file_name` is the filename you want the model file written to.

`m` can be obtained from the call to `run_spineopt()`. In Spine Toolbox, more particularly the run\_SpineOpt tool, you will have `m=run_spineopt()`. That means that you can call `write_model_file(m;file_name)` in the console once SpineOpt has finished executing and the console remains open.

```julia
using SpineOpt
m = run_spineopt(
    raw"sqlite:///C:\path\to\your\inputputdb.sqlite", 
    raw"sqlite:///C:\path\to\your\outputdb.sqlite";
    optimize=false
    )
write_model_file(m; file_name="<path-with-file-name>")
```

The resulting file has the extension `*.so_model` in the especified path.

!!! note
    If running the previous code gives you an error, please try replacing the last line with `SpineOpt.write_model_file(m; file_name="<path-with-file-name>")`. This error might appear in previous versions of SpineOpt where the `write_model_file` was not exported as part of the SpineOpt package.

In either case, here are some tips if you are using this file for debugging. The file can be very large so often it is helpful to create a minimum example of your model with only one or two timesteps. In addition, in the call to run\_spineopt() you can add the keyword argument `optimize=false`, as in the example above, so it will just build the model and not attempt to solve it.

The function `write_model_file` formats the file nicely for the user's readability. However, if the model is too large, it skips the number of rows it prints. If you still want the complete file, you can also use the JuMP function `write_to_file` to print the model. For more details on the function, please visit the JuMP package documentation.

```julia
using JuMP
JuMP.write_to_file(m, filename="<path-with-file-name>")
```

## Printing a Single Constraint
For large models, the resulting model file can be very large. The `print_constraint` function allows you to print a single constraint to a file. The function takes two arguments:
 - a SpineOpt constraint reference
 - the path to the resulting output file

Example:

```julia
print_constraint(
    m.ext[:spineopt].constraints[:investment_group_minimum_capacity_invested_available],
    "c:\\path\\to\\constraint.txt"
)
```
You will see that the first argument takes the form m.ext[:spineopt].constraints[:constraint_name]

Here is a list of constraint names current as of 12/11/2026. Consult the actual constraint code in \src\constraints for a specific up to date constraint name

| Column 1 | Column 2 | Column 3 |
|---|---|---|
| :min_node_pressure | :investment_group_equal_investments | :unit_flow_op_rank |
| :max_ratio_in_out_unit_flow | :max_ratio_out_in_unit_flow | :operating_point_bounds |
| :ramp_up | :compression_ratio | :fix_node_pressure_point |
| :investment_group_maximum_capacity_invested_available | :max_ratio_in_in_unit_flow | :connection_flow_lodf |
| :min_ratio_out_in_connection_flow | :min_total_cumulated_unit_flow_to_node | :connections_invested_transition |
| :min_ratio_out_in_unit_flow | :min_ratio_in_out_unit_flow | :min_ratio_in_in_unit_flow |
| :user_constraint | :unit_flow_op_rank | :unit_flow_ub |
| :connection_flow_lb | :operating_point_bounds | :max_total_cumulated_unit_flow_to_node |
| :connection_flow_fix | :fix_node_pressure_point | :min_capacity_margin |
| :investment_group_equal_investments | :connection_flow_lodf | :node_voltage_angle |
| :max_ratio_out_in_unit_flow | :connections_invested_transition | :non_spinning_reserves_start_up_upper_bound |
| :compression_ratio | :min_ratio_in_in_unit_flow | :node_state_capacity |
| :max_ratio_in_in_unit_flow | :unit_flow_ub | :max_ratio_out_out_unit_flow |
| :min_total_cumulated_unit_flow_to_node | :max_total_cumulated_unit_flow_to_node | :connection_intact_flow_ptdf |
| :min_ratio_in_out_unit_flow | :min_capacity_margin | :storage_lifetime |
| :unit_flow_op_rank | :node_voltage_angle | :investment_group_maximum_entities_invested_available |
| :operating_point_bounds | :non_spinning_reserves_start_up_upper_bound | :min_total_cumulated_unit_flow_from_node |
| :fix_node_pressure_point | :node_state_capacity | :storages_invested_transition |
| :connection_flow_lodf | :max_ratio_out_out_unit_flow | :unit_flow_op_sum |
| :connections_invested_transition | :connection_intact_flow_ptdf | :cyclic_node_state |
| :min_ratio_in_in_unit_flow | :storage_lifetime | :units_out_of_service_contiguity |
| :unit_flow_ub | :investment_group_maximum_entities_invested_available | :connection_flow_ub |
| :max_total_cumulated_unit_flow_to_node | :min_total_cumulated_unit_flow_from_node | :max_total_cumulated_unit_flow_from_node |
| :min_capacity_margin | :storages_invested_transition | :investment_group_minimum_capacity_invested_available |
| :node_voltage_angle | :unit_flow_op_sum | :ramp_down |
| :non_spinning_reserves_start_up_upper_bound | :cyclic_node_state | :connection_lifetime |
| :node_state_capacity | :units_out_of_service_contiguity | :min_node_state_longterm |
| :max_ratio_out_out_unit_flow | :connection_flow_ub | :min_down_time |
| :connection_intact_flow_ptdf | :max_total_cumulated_unit_flow_from_node | :storages_invested_available |
| :storage_lifetime | :investment_group_minimum_capacity_invested_available | :non_spinning_reserves_lower_bound |
| :investment_group_maximum_entities_invested_available | :ramp_down | :connection_unitary_gas_flow |
| :min_total_cumulated_unit_flow_from_node | :connection_lifetime | :unit_flow_lb |
| :storages_invested_transition | :min_node_state_longterm | :min_up_time |
| :unit_flow_op_sum | :min_down_time | :minimum_operating_point |
| :cyclic_node_state | :storages_invested_available | :fix_ratio_in_in_unit_flow |
| :units_out_of_service_contiguity | :non_spinning_reserves_lower_bound | :unit_flow_fix |
| :connection_flow_ub | :connection_unitary_gas_flow | :fix_ratio_in_out_unit_flow |
| :max_total_cumulated_unit_flow_from_node | :unit_flow_lb | :fix_ratio_out_out_unit_flow |
| :investment_group_minimum_capacity_invested_available | :min_up_time | :unit_flow_capacity |
| :ramp_down | :minimum_operating_point | :nodal_balance |
| :connection_lifetime | :fix_ratio_in_in_unit_flow | :fix_ratio_out_in_unit_flow |
| :min_node_state_longterm | :unit_flow_fix | :units_out_of_service_transition |
| :min_down_time | :fix_ratio_in_out_unit_flow | :max_ratio_out_in_connection_flow |
| :storages_invested_available | :fix_ratio_out_out_unit_flow | :unit_state_transition |
| :non_spinning_reserves_lower_bound | :unit_flow_capacity | :min_node_voltage_angle |
| :connection_unitary_gas_flow | :nodal_balance | :fix_ratio_out_in_connection_flow |
| :unit_flow_lb | :fix_ratio_out_in_unit_flow | :unit_flow_op_bounds |
| :min_up_time | :units_out_of_service_transition | :storage_line_pack |
| :minimum_operating_point | :max_ratio_out_in_connection_flow | :connection_flow_capacity |
| :fix_ratio_in_in_unit_flow | :unit_state_transition | :max_node_pressure |
| :unit_flow_fix | :min_node_voltage_angle | :min_scheduled_outage_duration |
| :fix_ratio_in_out_unit_flow | :fix_ratio_out_in_connection_flow | :node_injection |
| :fix_ratio_out_out_unit_flow | :unit_flow_op_bounds | :operating_point_rank |
| :unit_flow_capacity | :storage_line_pack | :node_state_longterm_trajectory |
| :nodal_balance | :connection_flow_capacity | :min_ratio_out_out_unit_flow |
| :fix_ratio_out_in_unit_flow | :max_node_pressure | :units_available |
| :units_out_of_service_transition | :min_scheduled_outage_duration | :node_state_longterm_capacity |
| :max_ratio_out_in_connection_flow | :node_injection | :lt_node_state_slack |
| :unit_state_transition | :operating_point_rank | :connection_min_flow |
| :min_node_voltage_angle | :node_state_longterm_trajectory | :min_node_state |
| :fix_ratio_out_in_connection_flow | :min_ratio_out_out_unit_flow | :max_node_voltage_angle |
| :unit_flow_op_bounds | :units_available | :connections_invested_available |
| :storage_line_pack | :node_state_longterm_capacity | :units_invested_transition |
| :connection_flow_capacity | :lt_node_state_slack | :units_invested_available |
| :max_node_pressure | :connection_min_flow | :connection_flow_gas_capacity |
| :min_scheduled_outage_duration | :min_node_state | :investment_group_minimum_entities_invested_available |
| :node_injection | :max_node_voltage_angle | :unit_lifetime |
| :operating_point_rank | :connections_invested_available | :non_spinning_reserves_shut_down_upper_bound |
| :node_state_longterm_trajectory | :units_invested_transition | |
| :min_ratio_out_out_unit_flow | :units_invested_available | |
| :units_available | :connection_flow_gas_capacity | |
| :node_state_longterm_capacity | :investment_group_minimum_entities_invested_available | |
| :lt_node_state_slack | :unit_lifetime | |
| :connection_min_flow | :non_spinning_reserves_shut_down_upper_bound | |
