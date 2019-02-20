# Load required packaes
using Revise
using SpineModel
using JuMP
using Clp

# Export contents of database into the current session
db_url = "sqlite:///examples/data/testsystemA4.sqlite"
JuMP_all_out(db_url)

# Init model
m = Model(solver=ClpSolver())

# Create decision variables
state = generate_variable_state(m)
flow = generate_variable_flow(m)
trans = generate_variable_trans(m)

# Bounds for state variables
# These should be integrated into generate_variable_state, if only I knew how
for (c, n) in commodity__node(), t=1:number_of_timesteps(time=:timer)
    state_lower_bound(commodity=c, node=n, t=t) != nothing && setlowerbound(state[c, n, t], state_lower_bound(commodity=c, node=n, t=t))
    state_upper_bound(commodity=c, node=n, t=t) != nothing && setupperbound(state[c, n, t], state_upper_bound(commodity=c, node=n, t=t))
end

# Create objective function
objective_minimize_production_cost(m, flow)

# Add technological constraints
# Unit capacity
constraint_flow_capacity(m, flow)

# Ratio of in/out flows of a unit
constraint_fix_ratio_out_in_flow(m, flow)

# Transmission losses
constraint_trans_loss(m, trans)

# Transmission line capacity
constraint_trans_cap(m, trans)

# Nodal balance
constraint_nodal_balance(m, state, flow, trans)

# Absolute bounds on commodities
constraint_max_cum_in_flow_bound(m, flow)

# needed: set/group of unitgroup CHP and Gasplant

# Run model
status = solve(m)
if status == :Optimal
    db_url_out = "sqlite:///examples/data/testsystemA4.sqlite"
    # JuMP_results_to_spine_db!(db_url; flow=flow, trans=trans)
    JuMP_results_to_spine_db!(db_url_out, db_url; state=state, flow=flow)
end
