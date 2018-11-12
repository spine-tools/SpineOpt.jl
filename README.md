# SpineModel.jl

A Julia Module to generate, run, and develop energy system integration models using the Spine framework.
See [Spine](http://www.spine-model.org/) for more information.

## Getting started

### Pre-requisites

- [Julia < 0.7](https://julialang.org/)
- [PyCall](https://github.com/JuliaPy/PyCall.jl)
- [CSV](https://github.com/JuliaData/CSV.jl)
- [JuMP](https://github.com/JuliaOpt/JuMP.jl)
- [JSON](https://github.com/JuliaIO/JSON.jl)
- [Clp](https://github.com/JuliaOpt/Clp.jl)
- [Missings](https://github.com/JuliaData/Missings.jl)
- [DataFrames](https://github.com/JuliaData/DataFrames.jl)
- [spinedatabase_api](https://gitlab.vtt.fi/spine/data/tree/database_api)

### Installation

From the julia REPL, run

```julia
julia> Pkg.clone("https://github.com/Spine-project/Spine-Model.git", "SpineModel")
```

This will install `SpineModel.jl` as well as all its Julia dependencies. `spinedatabase_api` (which is more
like a 'Python dependency') will be automatically installed the first time you load the module,
in the Python version used by `PyCall.jl`.

Note: you can reconfigure `PyCall.jl` to use any Python version in your system.
For instance, you can make it use the Python where Spine Toolbox is installed.
Check out the [PyCall documentation](https://github.com/JuliaPy/PyCall.jl) to learn more.

### Upgrading

To upgrade to the most recent version of `SpineModel.jl`, run


```julia
julia> Pkg.checkout("SpineModel")
```

Alternatively, you can specify a branch, as in

```julia
julia> Pkg.checkout("SpineModel", "dev")
```


### Usage

Run:

```
julia> using SpineModel
```

## Documentation

Documentation is available [here](docs/build/index.md).

## Reporting Issues and Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

Spine Model is licensed under GNU Lesser General Public License version 3.0 or later.
