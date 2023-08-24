A penalty for violating the [mp\_min\_res\_gen\_to\_demand\_ratio](@ref).
If set, then the lower bound on the fraction of the total system demand
that must be supplied by RES becomes a 'soft' constraint.
A new cost term is added to the objective, mutlitplying the penalty by the slack.