# Library

Documentation for `SpineOpt.jl`.

## Contents

```@contents
Pages = ["library.md"]
Depth = 3
```

## Index

```@index
```


## Public interface

```@docs
@fetch
@log
@timelog
active_stochastic_paths
add_event_handler!
build_model!
connection_flow_capacity
connection_flow_indices
connection_flow_lower_limit
create_model
current_window
forced_outage_time_series
generate_economic_structure!
generate_forced_outages
generate_stochastic_structure!
generate_temporal_structure!
master_model
node_state_capacity
node_state_indices
node_state_lower_limit
prepare_spineopt
rewind_temporal_structure!
roll_temporal_structure!
run_spineopt
run_spineopt!
solve_model!
SpineOptExt
stage_model
t_before_t
t_in_t
t_in_t_excl
t_overlaps_t
time_slice
to_time_slice
unit_flow_capacity
unit_flow_indices
unit_flow_op_indices
units_invested_available_indices
units_on_indices
upgrade_db
write_model_file
write_report
write_report_from_intermediate_results
```


## Internals

```@docs
SpineOpt.add_expression_capacity_margin!
SpineOpt.generate_direction_and_reorganise_classes
SpineOpt.indices
```