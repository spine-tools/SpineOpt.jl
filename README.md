# SpineData

A Julia Module to perform multiple data operations for the Spine project. It provides:
- Functions to convert data from the Spine format into algorithmic, [JuMP](https://github.com/JuliaOpt/JuMP.jl)-friendly format.


## Getting started

### Pre-requisites

- Julia 6.0+

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

This example assumes that an ODBC Data Source called "FirstTestData" has been configured using the `FirstTestDataNew.xlsx` file in the `examples` folder ([instructions for Windows](https://msdn.microsoft.com/en-us/library/2x0tte0f.aspx#Anchor_0)).

The program below builds a Spine data object (sdo) and a JuMP-friendly object (jfo) from the above database:

```
using SpineData
sdo = read_sdo_from_database("FirstTestData")
jfo = build_jfo_from_database("FirstTestData")
```
