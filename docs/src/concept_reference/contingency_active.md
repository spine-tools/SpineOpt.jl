Specifies that the connection in question is to be included as a contingency when security constrained unit commitment is enabled. When using security constrained unit commitment by setting [physics\_type](@ref) to [lodf\_physics](@ref grid_physics_list), an N-1 security constraint is created for each monitored line (`monitoring_active` = `true`) for each specified contingency (`contingency_active` = `true`).

See also [powerflow](@ref ptdf-based-powerflow)
