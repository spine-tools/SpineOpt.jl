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
- [DataFrames]
- [spinedatabase_api](https://gitlab.vtt.fi/spine/data/tree/database_api)

### Installation

`SpineModel.jl` is installed as any Julia package.

#### Julia < 0.7

From the julia REPL, run

```julia
julia> Pkg.clone("https://github.com/Spine-project/Spine-Model.git", "SpineModel")
```

That's it. Later on, to upgrade to the most recent version, run


```julia
julia> Pkg.checkout("SpineModel")
```

To upgrade to the most recent version from the development branch, run

```julia
julia> Pkg.checkout("SpineModel", "dev")
```

#### Julia >= 0.7

From the julia REPL, run

```julia
Pkg.add(PackageSpec(url="https://github.com/Spine-project/Spine-Model.git", name="SpineModel", rev="dev"))
```


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
