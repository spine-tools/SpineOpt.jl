This parameter selects how SpineOpt solves investments and operations:

`spineopt_standard` (the default) solves investments and operations in the same problem.

`spineopt_benders` uses Benders decomposition: investments are optimised in a master problem
and operations in sub problems, see [Decomposition](@ref).

`spineopt_other` is currently treated like `spineopt_standard`.

The algorithm to run, e.g. Modelling to generate alternatives, is selected with [model\_algorithm](@ref).
