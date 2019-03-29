
# Load required packaes
using Revise
using SpineModel
using Dates
using JuMP
using Clp
##
# Export contents of database into the current session
db_url = "sqlite:///examples/data/new_temporal.sqlite"
JuMP_all_out(db_url)

# Create temporal_structure
(timeslicemap,timeslicemap_detail,duration) = generate_timeslicemap()
#@Maren: duration() returns an array instead of a dict as what JuMP_all_out would return for a parameter convenience function
#@Maren: can we rename timeslicemap to time_slice() (in line with data conventions); and similarly generate_timeslicemap to generate_time_slice ?
(t_before_t,t_in_t,t_in_t_excl)=generate_hierarchy(timeslicemap_detail)
#@Maren: can we rename generate_hierarchy to generate_time_slice_relationships?

####
# Init model
m = Model(with_optimizer(Clp.Optimizer))
##
# Create decision variables
flow = generate_variable_flow(m, timeslicemap)
trans = generate_variable_trans(m, timeslicemap)
stor_state = generate_variable_stor_state(m, timeslicemap)
## Create objective function
production_cost = objective_minimize_production_cost(m, flow,timeslicemap)

# Add technological constraints
# Unit capacity
constraint_flow_capacity(m, flow, timeslicemap)

# Ratio of in/out flows of a unit
constraint_fix_ratio_out_in_flow(m, flow, timeslicemap, t_in_t)

# Transmission losses
#constraint_trans_loss(m, trans)
constraint_fix_ratio_out_in_trans(m, trans, timeslicemap, t_in_t)

# Transmission line capacity
constraint_trans_capacity(m, trans, timeslicemap)

# Nodal balance
constraint_nodal_balance(m, flow, trans, timeslicemap, t_in_t)

# Absolute bounds on commodities
constraint_max_cum_in_flow_bound(m, flow, timeslicemap)

# storage capacity
constraint_stor_capacity(m,stor_state, timeslicemap)

# storage state balance equation
constraint_stor_state_init(m, stor_state, timeslicemap)
constraint_stor_state(m, stor_state,trans,flow, timeslicemap, t_before_t)

# needed: set/group of unitgroup CHP and Gasplant

# Run model
optimize!(m)
status = termination_status(m)
if status == MOI.OPTIMAL
    db_url_out = db_url
    JuMP_results_to_spine_db!(db_url_out, db_url; trans=trans, flow=flow, stor_state=stor_state)
end
