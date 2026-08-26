Penalty terms for violating the [user\_constraint](@ref) in question.
By default (value `nothing`), the [positive](@ref var_user_constraint_slack_pos)
and [negative](@ref var_user_constraint_slack_neg) slack variables are omitted.
Effectively, this means that the [user\_constraint](@ref) is treated as absolute,
with zero violations allowed.

Defining a value for this variable spawns the slack variables.
However, note that both the [positive](@ref var_user_constraint_slack_pos)
and [negative](@ref var_user_constraint_slack_neg) slacks are currently always included.
There is no way to include only the other slack,
nor is it possible to define "asymmetric" penalties for them.