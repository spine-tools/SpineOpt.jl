# SpineModel.jl

A julia Module to generate, run, and develop energy system integration models using the Spine framework.
See [Spine](http://www.spine-model.org/) for more information.

## Getting started

### Pre-requisites

- [julia < 0.7](https://julialang.org/)
- [PyCall](https://github.com/JuliaPy/PyCall.jl)
- [CSV](https://github.com/JuliaData/CSV.jl)
- [JuMP](https://github.com/JuliaOpt/JuMP.jl)
- [JSON](https://github.com/JuliaIO/JSON.jl)
- [Clp](https://github.com/JuliaOpt/Clp.jl)
- [Missings](https://github.com/JuliaData/Missings.jl)
- [DataFrames](https://github.com/JuliaData/DataFrames.jl)
- [spinedatabase_api](https://github.com/Spine-project/Spine-Database-API)

### Installation

Start the julia REPL and run

```julia
Pkg.clone("https://github.com/Spine-project/Spine-Model.git", "SpineModel")
```

This will install `SpineModel.jl` and all its dependencies, except for `spinedatabase_api` which is
a Python package and thus needs to be installed separately.

#### Installing spinedatabase_api

If you have already installed `spinedatabase_api` to use it in [Spine Toolbox](https://github.com/Spine-project/Spine-toolbox), you can also use it in Spine Model.
All you need to do is configure PyCall to use the same python Spine Toolbox is using. In the julia REPL, run

```julia
using PyCall
ENV["PYTHON"] = "... path of the python program you want ..."
Pkg.build("PyCall")
```

and restar julia afterwards.

If you haven't installed `spinedatabase_api` yet or don't want to reconfigure PyCall, then you need to do the following:

1. Find out the path of the python program used by PyCall. In the julia REPL, run

   ```julia
   using PyCall
   PyCall.pyprogramname
   ```
2. Install `spinedatabase_api` in that python. Open a terminal (e.g. command prompt
   on Windows) and run

   ```
   python -m pip install git+https://github.com/Spine-project/Spine-Database-API.git
   ```

   where `python` is the path returned by `PyCall.pyprogramname`.

### Upgrading

In the julia REPL, run

```julia
Pkg.checkout("SpineModel")
```

This will upgrade `SpineModel.jl` to its most recent version.
Alternatively, to upgrade to the most recent **development** version, run

```julia
Pkg.checkout("SpineModel", "dev")
```

### Usage

In julia, run

```
using SpineModel
```

## Documentation

Documentation is available [here](docs/build/index.md).

## Reporting Issues and Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

Spine Model is licensed under GNU Lesser General Public License version 3.0 or later.
