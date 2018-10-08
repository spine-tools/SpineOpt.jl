# SpineModel.jl

A Julia Module to use within the [Spine](http://www.spine-model.org/) software suite, for developing energy system integration models,

## Getting started

### Pre-requisites

- [Julia 0.6.1+](https://julialang.org/)
- [PyCall](https://github.com/JuliaPy/PyCall.jl)
- [CSV](https://github.com/JuliaData/CSV.jl)
- [JuMP](https://github.com/JuliaOpt/JuMP.jl)
- [JSON](https://github.com/JuliaIO/JSON.jl)
- [Clp](https://github.com/JuliaOpt/Clp.jl)
- [Missings](https://github.com/JuliaData/Missings.jl)
- [spinedatabase_api](https://gitlab.vtt.fi/spine/data/tree/database_api)

### Installation

In the Julia REPL, issue the following command to clone this repo into your package directory:

```julia
julia> Pkg.clone("<path to the repository>", "SpineModel")
```

Checkout the current branch (`dev`):

```julia
julia> Pkg.checkout("SpineModel", "dev")
```

In the future, whenever you want to get the latest version of the package
just run the `Pkg.checkout(...)` part.

### Usage

Include the module in your Julia session or program:

```
julia> using SpineModel
```

## Documentation

Documentation is available [here](docs/build/index.md).

## Reporting Issues and Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

Spine Model is licensed under GNU Lesser General Public License version 3.0 or later.
