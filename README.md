# SpineModel.jl

A Julia Module for defining and running energy models using the  [Spine](http://www.spine-model.org/) framework.

## Getting started

### Pre-requisites

- Julia 0.6+

### Installation

In the Julia REPL, issue the following command to clone this repo into a package named `SpineModel`:

```julia
julia> Pkg.clone("https://gitlab.vtt.fi/spine/model.git", "SpineModel")
```

Checkout the current branch (`manuelma`):

```julia
julia> Pkg.checkout("SpineModel", "manuelma")
```

### Usage

Include the module in your Julia session or program:

```
julia> using SpineModel
```


## Examples

### Read data in the Spine format from an Excel database


The example below builds a JuMP-friendly object (jfo) from an ODBC database given by "FirstTestData":

```julia
# load the module
using SpineModel

#  build a JuMP-friendly object
jfo = JuMP_object("FirstTestData")

# Create variables from relevant keys
@JuMPout(jfo, bus, gen, pmax, pmin, gen_bus)
```


## Documentation

Documentation is available [here](docs/build/index.md).
