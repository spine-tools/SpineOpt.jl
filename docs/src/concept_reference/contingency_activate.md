Specifies that the connection in question is to be included as a contingency when security constrained unit commitment is enabled. When using security constrained unit commitment by setting [physics\_type](@ref) to [commodity\_physics\_lodf](@ref commodity_physics_list), an N-1 security constraint is created for each monitored line (`monitoring_activate` = `true`) for each specified contingency (`contingency_activate` = `true`).

See also [powerflow](@ref ptdf-based-powerflow)
