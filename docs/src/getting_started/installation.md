# Installation

TODO: Explain what is needed to install *SpineOpt*, *Spine Toolbox*, etc. so that one is ready to start
working on creating models or running optimizations.

## Compatibility

This package requires Julia 1.2 or later.

## Prerequisites

To make use of the full functionality of SpineOpt, we strongly recommend the installation of [Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox).
SpineToolbox provides all the necessary tools for data management required by SpineOpt.

## How to Install

```julia
julia> using Pkg

julia> pkg"registry add https://github.com/Spine-project/SpineJuliaRegistry"

julia> pkg"add SpineOpt"

```