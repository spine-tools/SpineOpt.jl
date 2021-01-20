# SpineOpt.jl

[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://spine-project.github.io/SpineOpt.jl/latest/index.html)
[![Build Status](https://travis-ci.com/Spine-project/SpineOpt.jl.svg?branch=master)](https://travis-ci.com/Spine-project/SpineOpt.jl)
[![Coverage Status](https://coveralls.io/repos/github/Spine-project/SpineOpt.jl/badge.svg?branch=master)](https://coveralls.io/github/Spine-project/SpineOpt.jl?branch=master)
[![codecov](https://codecov.io/gh/Spine-project/SpineOpt.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Spine-project/SpineOpt.jl)

A package to run an energy system integration model called SpineOpt.

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

## Building the documentation

The SpineOpt documentation is bundled in with the model itself, and can be built locally.
First, **navigate into the SpineOpt main folder** and activate the `docs` environment from the julia package manager:

```julia
(SpineOpt) pkg> activate docs
(docs) pkg>
```

Next, in order to make sure that the `docs` environment uses the same SpineOpt version it is contained within,
install the package locally into the `docs` environment:

```julia
(docs) pkg> develop .
Resolving package versions...
<lots of packages being checked>
(docs) pkg>
```

Now, you should be able to build the documentation by exiting the package manager and typing:

```julia
julia> include("docs/make.jl")
```

This should build the documentation on your computer, and you can access it in the `docs/build/` folder.

## Reporting Issues and Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

SpineOpt is licensed under GNU Lesser General Public License version 3.0 or later.
