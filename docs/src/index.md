# SpineModel.jl

*The Spine Model generator.*

A package to generate and run the Spine Model for energy system integration problems.

## Package features

- Builds the model entirely from a database using Spine Model specific data structure.
- Uses `JuMP.jl` to build and solve the optimization model.
- Writes results to the same input database or to a different one.
- The model can be extended with additional constraints written in `JuMP`.
- Supports Julia `1.0`.


## Library outline

```@contents
Pages = ["library.md"]
Depth = 3
```
