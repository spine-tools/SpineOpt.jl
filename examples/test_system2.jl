# Load required packaes
using Revise
include("../src/SpineModel.jl")
using Main.SpineModel
using JuMP
using Clp

# Export contents of database into the current session
db_url = "sqlite:///examples/data/testsystem2_v2_multiD.sqlite"
JuMP_all_out(db_url; upgrade=true)

# Init model
m = Model(with_optimizer(Clp.Optimizer))

# Create decision variables
flow = generate_variable_flow(m)
trans = generate_variable_trans(m)
state = generate_variable_state(m)

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
optimize!(m)
status = termination_status(m)
if status == MOI.OPTIMAL
    db_url_out = db_url
    # JuMP_results_to_spine_db!(db_url; flow=flow, trans=trans)
    JuMP_results_to_spine_db!(db_url_out, db_url; state=state, flow=flow, trans=trans)
end
