MIP solver options are specified for a model using the [db\_mip\_solver\_options](@ref) parameter. This parameter value must take the form of a nested map
where the outer key corresponds to the solver package name (case sensitive). E.g. `Cbc.jl`. The inner map consists of option name and value pairs. See the below example. 
By default, the SpineOpt template contains some common parameters for some common solvers. For a list of supported solver options, one should consult
the documentation for the solver and//or the julia solver wrapper package.
![example db_mip_solver_options map parameter](https://user-images.githubusercontent.com/7080191/155577992-b9dbf284-390b-4df4-b4f3-52b5d0a603d9.png)