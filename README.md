# SpineModel.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://spine-project.github.io/Spine-Model/latest/index.html)

A package to run energy system integration models using the Spine framework.
See [Spine](http://www.spine-model.org/) for more information.

## Getting started

### Pre-requisites

- [julia 1.0](https://julialang.org/)
- [JuMP](https://github.com/JuliaOpt/JuMP.jl)
- [Clp](https://github.com/JuliaOpt/Clp.jl)
- [SpineInterface](https://github.com/Spine-project/SpineInterface.jl)

### Installation

Julia <= 1.1 does not allow to set unregistered packages as dependencies. Until that changes (hopefully pretty soon, see [here](https://github.com/JuliaLang/Pkg.jl/pull/1088)), one needs to install the unregistered dependency, in this case SpineInterface, by hand.

From the Julia REPL, press the key `]` to enter the Pkg-REPL mode, then run

```julia
(v1.0) pkg> add https://github.com/Spine-project/SpineInterface.jl.git
(v1.0) pkg> add https://github.com/Spine-project/Spine-Model.git
```

### Upgrading

To upgrade to the most recent version, enter the Pkg-REPL mode and run

```julia
(v1.0) pkg> up SpineModel
```

### Usage

In julia, run

```
using SpineModel
```

## Reporting Issues and Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

Spine Model is licensed under GNU Lesser General Public License version 3.0 or later.
