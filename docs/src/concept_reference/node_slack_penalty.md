`node_slack_penalty` triggers the creation of node slack variables, `node_slack_pos` and `node_slack_neg`.
This allows the model to violate the [node\_balance](@ref constraint_nodal_balance) constraint with these violations penalised in the objective function
with a coefficient equal to `node_slack_penalty`. If `node_slack_penalty` = 0 the slack variables are created and violations are
unpenalised. If set to none or undefined, the variables are not created and violation of the [node\_balance](@ref constraint_nodal_balance) constraint is 
not possible.
