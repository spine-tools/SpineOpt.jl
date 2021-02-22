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
run_spineopt(::String, ::String)
run_spineopt(::String)
```


## Internals

### Variable library

```@docs
variable_flow
variable_connection_flow
variable_units_on
flow_indices
var_flow_indices
fix_unit_flow_indices
connection_flow_indices
var_connection_flow_indices
fix_connection_flow_indices
units_on_indices
var_units_on_indices
fix_units_on_indices
```

### Constraint library

TODO

### Objective

TODO
