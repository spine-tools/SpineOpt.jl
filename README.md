# SpineOpt.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://spine-project.github.io/SpineOpt.jl/latest/index.html)

A package to run the [Spine](http://www.spine-model.org/) energy system integration model.

## Compatibility

This package requires Julia 1.2 or later.

## Installation

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

## Reporting Issues and Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

SpineOpt is licensed under GNU Lesser General Public License version 3.0 or later.
