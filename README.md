# SpineModel.jl

A Julia Module to run simulations using data in the Spine format. It provides:
- Functions to translate Spine data objects into  [JuMP](https://github.com/JuliaOpt/JuMP.jl)-friendly objects.
- Functions and macros to manipulate JuMP-friendly objects.


## Getting started

### Pre-requisites

- Julia 0.6+

### Installation

In the Julia REPL, use the package manager to clone this repo into your Julia library as a package named `SpineModel`:

```
julia> Pkg.clone("https://gitlab.vtt.fi/spine/model.git", "SpineModel")
```

Checkout the current branch:

```
julia> Pkg.checkout("SpineModel", "manuelma")
```

### Usage

Include the module in your Julia REPL session or program:

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

Documentation is available [here](index.md).
