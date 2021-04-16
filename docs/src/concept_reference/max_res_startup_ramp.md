A unit can provide spinning and nonspinning reserves to a [reserve node](@ref is_reserve_node). These reserves can be either [upward\_reserve](@ref) or [downward\_reserve](@ref).
Nonspinning upward reserves are provided to a [upward\_reserve](@ref) node by contracted offline units holding available to startup. To include the provision of nonspinning upward reserves, the parameter [max\_res\_startup\_ramp](@ref) needs to be defined on the corresponding [unit\_\_to\_node](@ref) relationship. This will trigger the generation of the variables
[nonspin\_units\_started\_up](@ref) and [nonspin\_ramp\_up\_unit\_flow](@ref) and the constraint [on maximum upward nonspinning reserve provision](@ref constraint_max_nonspin_ramp_up).
Note that [max\_res\_startup\_ramp](@ref) is given as a fraction of the [unit\_capacity](@ref).

A detailed description of the usage of ramps and reserves is given in the chapter [Ramping and Reserves](@ref Ramping-and-Reserves). The chapter [Ramping and reserve constraints](@ref) in the Mathematical Formulation presents the equations related to ramps and reserves.
