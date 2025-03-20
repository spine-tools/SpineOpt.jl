When using ptdf-based load flow by setting [physics\_type](@ref) to either [grid\_physics\_ptdf](@ref grid_physics_list) or [grid\_physics\_ptdf](@ref grid_physics_list), a constraint is created for each connection for which `monitoring_activate` = `true`. Thus, to monitor the ptdf-based flow on a particular connection `monitoring_activate` must be set to `true`.

See also [powerflow](@ref ptdf-based-powerflow)
