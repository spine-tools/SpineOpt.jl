# SpineOpt.jl

[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://spine-project.github.io/SpineOpt.jl/latest/index.html)
[![Build Status](https://travis-ci.org/Spine-project/SpineOpt.jl.svg?branch=dev)](https://travis-ci.org/Spine-project/SpineOpt.jl)
[![Coverage Status](https://coveralls.io/repos/github/Spine-project/SpineOpt.jl/badge.svg?branch=dev)](https://coveralls.io/github/Spine-project/SpineOpt.jl?branch=dev)
[![codecov](https://codecov.io/gh/Spine-project/SpineOpt.jl/branch/dev/graph/badge.svg)](https://codecov.io/gh/Spine-project/SpineOpt.jl)

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
run_spineopt("...url of a SpineOpt database...")
```

## Reporting Issues and Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

SpineOpt is licensed under GNU Lesser General Public License version 3.0 or later.
