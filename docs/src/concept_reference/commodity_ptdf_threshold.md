Given a [connection](@ref) and a [node](@ref), the power transfer distribution factor (PTDF)
is the fraction of the flow injected into the [node](@ref) that will flow on the [connection](@ref).
[commodity\_ptdf\_threshold](@ref) is the minimum absolute value of the PTDF that is considered meaningful.
Any value below this threshold (in absolute value) will be treated as zero.

The PTDFs are used to model DC power flow on certain [connections](@ref).
To model DC power flow on a [connection](@ref), set [connection\_monitored](@ref) to `true`.

In addition, define a [commodity](@ref) with [commodity\_physics](@ref) set to either [commodity\_physics\_ptdf](@ref),
or [commodity\_physics\_lodf](@ref).
and associate that [commodity](@ref) (via [node\_\_commodity](@ref)) to both [connection](@ref)s' [node](@ref)s
(given by [connection\_\_to\_node](@ref) and [connection\_\_from\_node](@ref)).
