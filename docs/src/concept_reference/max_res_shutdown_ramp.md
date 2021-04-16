A unit can provide spinning and nonspinning reserves to a [reserve node](@ref is_reserve_node). These reserves can be either [upward\_reserve](@ref) or [downward\_reserve](@ref).
Nonspinning downward reserves are provided to a [downward\_reserve](@ref) node by contracted units holding available to shutdown. To include the provision of nonspinning downward reserves, the parameter [max\_res\_shutdown\_ramp](@ref) needs to be defined on the corresponding [unit\_\_to\_node](@ref) relationship. This will trigger the generation of the variables
[nonspin\_units\_shut\_down and nonspin\_ramp\_down\_unit_flow](@ref Variables) and the constraint [on maximum downward nonspinning reserve provision](@ref constraint_max_nonspin_ramp_down).
Note that [max\_res\_shutdown\_ramp](@ref) is given as a fraction of the [unit\_capacity](@ref).

A detailed description of the usage of ramps and reserves is given in the chapter [Ramping and Reserves](@ref Ramping-and-Reserves). The chapter [Ramping and reserve constraints](@ref) in the Mathematical Formulation presents the equations related to ramps and reserves.
