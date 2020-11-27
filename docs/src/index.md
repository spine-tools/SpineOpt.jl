# Introduction

*SpineOpt.jl* is an integrated energy systems optimization model created as part of the 
[Spine project](http://www.spine-model.org/), striving towards adaptability for a multitude of modelling purposes.
The data-driven model structure allows for highly customizable energy system descriptions, as well as flexible
temporal and stochastic structures, without the need to alter the model source code directly.
The methodology is based on mixed-integer linear programming, and *SpineOpt* relies on
[*JuMP.jl*](https://github.com/JuliaOpt/JuMP.jl) for interfacing with the different solvers.

While, in principle, it is possible to run *SpineOpt* by itself, it has been designed to be used through the
[Spine toolbox](https://github.com/Spine-project/Spine-Toolbox), and take maximum advantage of the data and modelling
workflow management tools therein.
Thus, we highly recommend installing *Spine toolbox* as well, as outlined in the [Getting Started](@ref) guide.