# SpineOpt.jl

*The SpineOpt model generator.*

A package to generate and run optimization problems for energy system integration.

## Package features

- Builds the model entirely from a database using SpineOpt specific data structure.
- Uses `JuMP.jl` to build and solve the optimization model.
- Writes results to the same input database or to a different one.
- The model can be extended with additional constraints written in `JuMP`.
- Supports Julia `1.0`.


## Library outline

```@contents
Pages = ["library.md"]
Depth = 3
```
