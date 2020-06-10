# SpineOpt.jl

*The SpineOpt model generator.*

A package to generate and run optimization problems for energy system integration.

```julia
using Pkg
pkg"registry add https://github.com/Spine-project/SpineJuliaRegistry"
pkg"add SpineOpt"
```

## Usage

```julia
using SpineOpt
run_spineopt(<url of your Spine database>)
```

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
