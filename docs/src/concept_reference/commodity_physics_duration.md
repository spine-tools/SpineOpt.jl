This parameter determines the duration, relative to the start of the optimisation window,
over which the physics determined by [commodity\_physics](@ref) should be applied.
This is useful when the optimisation window includes a long look-ahead where the detailed physics are not
necessary. In this case one can set `commodity_physics_duration` to a shorter value to reduce problem size
and increase performace.

See also [powerflow](@ref ptdf-based-powerflow)
