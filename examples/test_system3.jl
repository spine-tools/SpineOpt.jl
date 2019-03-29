# Load required packaes
using Revise
using SpineModel
using Dates
using JuMP
using Clp



##
# Export contents of database into the current session
db_url = "sqlite:///examples/data/new_temporal.sqlite"

println("--------------------------------------------\n Creating convenience functions ")
@time begin
    JuMP_all_out(db_url)
end
println("Convenience functions created \n --------------------------------------------")


# Init model
println("--------------------------------------------\n Initializing model")
@time begin
    m = Model(with_optimizer(Clp.Optimizer))
end
println("Model initialized \n --------------------------------------------")

# Create temporal_structure
println("--------------------------------------------\n Creating temporal structure")
@time begin
    timeslicemap = time_slicemap() #@Maren: propose to rename to time_slice_details = get_time_slice_details_from_temporal_block()
    timesliceblocks = time_slices_tempblock() #@Maren: do we need this?
    time_slice = timeslice(timeslicemap) # @Maren: I have added this "jump-like" version of which returns an array of time slices similar to what unit() would do
    t_before_t = generate_t_before_t(timeslicemap)
    t_in_t = generate_t_in_t(timeslicemap)
    t_in_t_excl = generate_t_in_t_excl(timeslicemap)
end
println("Temporal structure created \n --------------------------------------------")

# Create decision variables
println("--------------------------------------------\n Generating decision variables")
@time begin
    flow = generate_variable_flow(m, timesliceblocks)
    trans = generate_variable_trans(m, timesliceblocks)
    #stor_state = generate_variable_stor_state(m, timesliceblocks)
end
println("Decision variables generated \n --------------------------------------------")

## Create objective function
println("--------------------------------------------\n Creating objective function")
@time begin
    production_cost = objective_minimize_production_cost(m, flow, timeslicemap)
end
println("Objective function created \n --------------------------------------------")

# Add constraints
println("--------------------------------------------\n Generating constraints")
@time begin
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
    constraint_nodal_balance(m, flow, trans, timeslicemap,timesliceblocks)

    # Absolute bounds on commodities
    constraint_max_cum_in_flow_bound(m, flow, timeslicemap)

    # storage capacity
    #constraint_stor_capacity(m,stor_state, timeslicemap)

    # storage state balance equation
    #constraint_stor_state_init(m, stor_state, timeslicemap)
    #constraint_stor_state(m, stor_state,trans,flow, timeslicemap, t_before_t)

    # needed: set/group of unitgroup CHP and Gasplant
end
println("Constraints generated \n --------------------------------------------")

# Run model
println("--------------------------------------------\n Solving model")
@time begin
    optimize!(m)
    status = termination_status(m)
end
println("Model solved \n --------------------------------------------")


# Results to spine database
println("--------------------------------------------\n Writing results to the database")
@time begin
    if status == MOI.OPTIMAL
        db_url_out = db_url
        JuMP_results_to_spine_db!(db_url_out, db_url; trans=trans, flow=flow)
        println("Optimal solution found after")
    end
end
println("Results written to the database \n --------------------------------------------")

println("Objective function value: $(objective_value(m))")
