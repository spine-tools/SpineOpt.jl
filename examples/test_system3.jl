
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
println("--------------------------------------------\n Creating convenience functions ")
checkout_spinedb(db_url; upgrade=true)

# Create temporal_structure
(time_slice,time_slice_detail,duration) = generate_time_slice()
#@Maren: duration() returns an array instead of a dict as what JuMP_all_out would return for a parameter convenience function
(t_before_t,t_in_t,t_in_t_excl)=generate_time_slice_relationships(time_slice_detail)
println("Convenience functions created \n --------------------------------------------")
####
# Init model
println("--------------------------------------------\n Initializing model")
m = Model(with_optimizer(Clp.Optimizer))
##
# Create decision variables
flow = generate_variable_flow(m, time_slice)
trans = generate_variable_trans(m, time_slice)
stor_state = generate_variable_stor_state(m, time_slice)
## Create objective function
production_cost = objective_minimize_production_cost(m, flow, time_slice)

# Add constraints
println("--------------------------------------------\n Generating constraints")
@time begin
    # Unit capacity
    constraint_flow_capacity(m, flow, time_slice)

    # Ratio of in/out flows of a unit
    constraint_fix_ratio_out_in_flow(m, flow, time_slice, t_in_t)

    # Transmission losses
    #constraint_trans_loss(m, trans)
    constraint_fix_ratio_out_in_trans(m, trans, time_slice, t_in_t)

    # Transmission line capacity
    constraint_trans_capacity(m, trans, time_slice)

    # Nodal balance
    constraint_nodal_balance(m, flow, trans, time_slice, t_in_t)

    # Absolute bounds on commodities
    constraint_max_cum_in_flow_bound(m, flow, time_slice)

    # storage capacity
    constraint_stor_capacity(m,stor_state, time_slice)

    # storage state balance equation
    constraint_stor_state_init(m, stor_state, time_slice)
    constraint_stor_state(m, stor_state,trans,flow, time_slice, t_before_t)

    # needed: set/group of unitgroup CHP and Gasplant
end
println("Constraints generated \n --------------------------------------------")

# Run model
println("--------------------------------------------\n Solving model")
@time begin
    optimize!(m)
end
println("Model solved \n --------------------------------------------")
status = termination_status(m)
if status == MOI.OPTIMAL
    println("Optimal solution found after")
    out_file = "$(@__DIR__)/data/new_temporal_out.sqlite"
    out_db_url = "sqlite:///$out_file"
    isfile(out_file) || create_results_db(out_db_url, db_url)
    write_results(
        out_db_url;
        flow=pack_trailing_dims(SpineModel.value(flow), 1),
        trans=pack_trailing_dims(SpineModel.value(trans), 1),
        stor_state=pack_trailing_dims(SpineModel.value(stor_state), 1),
    )
end
println("Results written to the database \n --------------------------------------------")
println("Objective function value: $(objective_value(m))")
