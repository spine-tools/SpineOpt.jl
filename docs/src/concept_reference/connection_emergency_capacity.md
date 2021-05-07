The [connection\_emergency\_capacity](@ref) parameter represents the maximum post-contingency flow on
a *monitored* [connection](@ref) if ptdf and lodf based security constrained unit commitment is enabled ([commodity\_physics](@ref) is set to [commodity\_physics\_lodf]).

If you set this value, make sure that you also set [connection\_monitored](@ref) to `true`
for the involved [connection](@ref).
