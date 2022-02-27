Specifies the Julia solver package to be used to solve Linear Programming Problems (LPs) for the specific [model](@ref). 
The value must correspond exactly (case sensitive) to the name of the Julia solver package (e.g. `Clp.jl`). Installation and configuration of
solvers is the responsibility of the user. A full list of solvers supported by JuMP can be found [here](https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers). 
Note that the specified problem must support LP problems. Solver options are specified using the [db\_lp\_solver\_options](@ref) parameter for the model.
Note also that if `run_spineopt()` is called with the lp_solver keyword argument specified, this will override this parameter.