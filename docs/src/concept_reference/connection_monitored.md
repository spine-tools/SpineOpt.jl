When using ptdf-based load flow by setting [commodity\_physics](@ref) to either [commodity\_physics\_ptdf](@ref commodity_physics_list) or [commodity\_physics\_ptdf](@ref commodity_physics_list), a constraint is created for each connection for which `connection_monitored` = `true`. Thus, to monitor the ptdf-based flow on a particular connection `connection_monitored` must be set to `true`.

See also [powerflow](@ref ptdf-based-powerflow)
