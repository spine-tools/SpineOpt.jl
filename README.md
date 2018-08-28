# SpineModel.jl

A Julia Module for defining and running energy models using the  [Spine](http://www.spine-model.org/) framework.

## Getting started

### Pre-requisites

- Julia 0.6+

### Installation

In the Julia REPL, issue the following command to clone this repo into your package directory:

```julia
julia> Pkg.clone("https://gitlab.vtt.fi/spine/model.git", "SpineModel")
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
