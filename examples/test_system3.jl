# Load required packaes
using Revise
using SpineModel
using Base.Dates
using Temporals
using JuMP
using Clp
##
# Export contents of database into the current session
db_url = "sqlite:///C:/Users/u0122387/Desktop/toolbox/projects/temporal_structure/input_timestorage/input_temporal2.sqlite"
JuMP_all_out(db_url)
duration()

# Init model
m = Model(solver=ClpSolver())

# Create decision variables
flow = generate_variable_flow(m)
trans = generate_variable_trans(m)
stor_state = generate_variable_stor_state(m)
## Create objective function
production_cost = objective_minimize_production_cost(m, flow)

# Add technological constraints
# Unit capacity
constraint_flow_capacity(m, flow)

# Ratio of in/out flows of a unit
constraint_fix_ratio_out_in_flow(m, flow)

# Transmission losses
#constraint_trans_loss(m, trans)
constraint_fix_ratio_out_in_trans(m, trans)

# Transmission line capacity
constraint_trans_capacity(m, trans)

# Nodal balance
constraint_nodal_balance(m, flow, trans)

# Absolute bounds on commodities
constraint_max_cum_in_flow_bound(m, flow)

# storage capacity
constraint_stor_capacity(m,stor_state)

# storage state balance equation
constraint_stor_state(m, stor_state,trans,flow)

# needed: set/group of unitgroup CHP and Gasplant

# Run model
status = solve(m)
if status == :Optimal
    db_url_out = "sqlite:///examples/data/testsystem3_db_out.sqlite"
    # JuMP_results_to_spine_db!(db_url; flow=flow, trans=trans)
    #JuMP_results_to_spine_db!(db_url_out, db_url; flow=flow, trans=trans, stor_state=stor_state)
end
