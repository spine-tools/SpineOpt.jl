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
run_spineopt
prepare_spineopt
run_spineopt!
create_model
build_model!
solve_model!
add_event_handler!
generate_temporal_structure!
roll_temporal_structure!
rewind_temporal_structure!
time_slice
t_before_t
t_in_t
t_overlaps_t
to_time_slice
current_window
generate_stochastic_structure!
active_stochastic_paths
write_model_file
output_value
write_report
write_report_from_intermediate_results
master_model
generate_forced_availability_factor
```
