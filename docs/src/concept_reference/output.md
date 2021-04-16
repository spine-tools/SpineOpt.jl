An [output](@ref) is essentially a handle for a *SpineOpt* [variable](@ref Variables) and
[Objective function](@ref) to be included in a [report](@ref) and written into an output database.
Typically, e.g. the [unit\_flow](@ref) variables are desired as output from most [model](@ref)s,
so creating an [output](@ref) object called `unit_flow` allows one to designate it as something to be written in the
desired [report](@ref).
Note that unless appropriate [model\_\_report](@ref) and [report\_\_output](@ref) relationships are defined,
*SpineOpt* doesn't write any output!