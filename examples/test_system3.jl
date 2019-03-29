
# Load required packaes
using Revise
using SpineInterface
using SpineModel
using Dates
using JuMP
using Clp
##
# Export contents of database into the current session
db_url = "sqlite:///$(@__DIR__)/data/new_temporal.sqlite"
checkout_spinedb(db_url; upgrade=true)

# Create temporal_structure
(timeslicemap,timeslicemap_detail,duration) = generate_timeslicemap()
(t_before_t,t_in_t,t_in_t_excl)=generate_hierarchy(timeslicemap_detail)
#t_in_t = generate_t_in_t(timeslicemap)
#t_in_t_excl = generate_t_in_t_excl(timeslicemap)
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
    out_db_url = "sqlite:///$(@__DIR__)/data/new_temporal_out.sqlite"
    write_results(
        out_db_url, db_url;
        upgrade=true,
        flow=pack_trailing_dims(SpineModel.value(flow), 1),
        trans=pack_trailing_dims(SpineModel.value(trans), 1),
        stor_state=pack_trailing_dims(SpineModel.value(stor_state), 1),
    )
end
