The [connection\_emergency\_capacity](@ref) parameter represents the maximum post-contingency flow on
a *monitored* [connection](@ref) if ptdf and lodf based security constrained unit commitment is enabled ([physics\_type](@ref) is set to [lodf\_physics]).

If you set this value, make sure that you also set [monitoring\_activate](@ref) to `true`
for the involved [connection](@ref).
