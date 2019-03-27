# Load required packaes
using Revise
using SpineModel
using Dates
using JuMP
using Clp
##
# Export contents of database into the current session
db_url = "sqlite:///C:/Users/u0093836/repos/git/model/examples/data/new_temporal.sqlite"
#db_url = "sqlite:///C:/Users/u0122387/Desktop/toolbox/projects/temporal_structure/input_timestorage/new_temporal.sqlite"
JuMP_all_out(db_url)
# Init model
m = Model(with_optimizer(Clp.Optimizer))
##
# Create temporal_structure
timeslicemap = time_slicemap() #@Maren: propose to rename to time_slice = get_time_slices()
# @Maren: do we also need a jump-like version of time_slice(). I have added such a function...
timesliceblocks = time_slices_tempblock() #@Maren: propose to rename to temporal_block = get_temporal_block()
t_before_t = generate_t_before_t(timeslicemap)
t_in_t = generate_t_in_t(timeslicemap)
t_in_t_excl = generate_t_in_t_excl(timeslicemap)

# Create decision variables
flow = generate_variable_flow(m, timesliceblocks)
trans = generate_variable_trans(m, timesliceblocks)
#stor_state = generate_variable_stor_state(m, timesliceblocks)
## Create objective function
production_cost = objective_minimize_production_cost(m, flow, timeslicemap)

# Add technological constraints
# Unit capacity
constraint_flow_capacity(m, flow, timeslicemap)

# Ratio of in/out flows of a unit
constraint_fix_ratio_out_in_flow(m, flow, timeslicemap, timesliceblocks, t_in_t)

# Transmission losses
#constraint_trans_loss(m, trans)
constraint_fix_ratio_out_in_trans(m, trans, timeslicemap, timesliceblocks, t_in_t)

# Transmission line capacity
constraint_trans_capacity(m, trans, timeslicemap)

# Nodal balance
constraint_nodal_balance(m, flow, trans, timeslicemap)

# Absolute bounds on commodities
constraint_max_cum_in_flow_bound(m, flow, timeslicemap)

# storage capacity
#constraint_stor_capacity(m,stor_state, timeslicemap)

# storage state balance equation
#constraint_stor_state_init(m, stor_state, timeslicemap)
#constraint_stor_state(m, stor_state,trans,flow, timeslicemap, t_before_t)

# needed: set/group of unitgroup CHP and Gasplant

# Run model
optimize!(m)
status = termination_status(m)
if status == MOI.OPTIMAL
    db_url_out = db_url
    JuMP_results_to_spine_db!(db_url_out, db_url; trans=trans, flow=flow)
end
