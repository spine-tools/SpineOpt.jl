# Load required packaes
using Revise
include("../src/SpineModel.jl")
using Main.SpineModel
using JuMP
using Clp


## Extend SpineModel.jl
# TODO: @Tasku can you briefly explain why these additions?
"""
    generate_variable_state(m::Model)

A `state` variable for each tuple returned by `commodity__node()`,
attached to model `m`.
`state` represents the 'commodity' stored  inside a 'node'.
"""
function generate_variable_state(m::Model)
    @butcher Dict{Tuple, JuMP.VariableRef}(
        (c, n, t) => @variable(
            m, base_name="state[$c, $n, $t]"
        ) for (c, n) in commodity__node(), t=0:number_of_timesteps(time=:timer)
    )
end


"""
    constraint_node_state_cyclic_bound(m::Model, state)

Fix the first and last modelled values of node state variables as equal.
"""
function constraint_node_state_cyclic_bound(m::Model, state)
    @butcher for (c,n) in commodity__node()
        state_cyclic_bound(commodity=c, node=n) != nothing || continue
        @constraint(
            m,
            # Node commodity state on the first time step
            state[c, n, 0]
            ==
            # Node commodity state on the last time step
            state[c, n, number_of_timesteps(time=:timer)]
        )
    end
end


## Override SpineModel.jl
# TODO: @Tasku can you briefly explain why the differences with respect to original constraints?
"""
    constraint_fix_ratio_out_in_flow(m::Model, flow)

Fix ratio between the output `flow` of a `commodity_group` to an input `flow` of a
`commodity_group` for each `unit` for which the parameter `fix_ratio_out_in_flow`
is specified.
"""
function constraint_fix_ratio_out_in_flow(m::Model, flow)
    @butcher @constraint(
        m,
        [
            u in unit(),
            cg_out in commodity_group(),
            cg_in in commodity_group(),
            t=1:number_of_timesteps(time=:timer);
            fix_ratio_out_in_flow(unit=u, commodity_group1=cg_out, commodity_group2=cg_in) != nothing
        ],
        + reduce(+,
            flow[c_out, n, u, :out, t]
            for (c_out, n) in commodity__node__unit__direction(unit=u, direction=:out)
            if c_out in commodity_group__commodity(commodity_group=cg_out);
                init=0
            )
        ==
        + fix_ratio_out_in_flow(unit=u, commodity_group1=cg_out, commodity_group2=cg_in)
            * reduce(+,
                flow[c_in, n, u, :in, t]
                for (c_in, n) in commodity__node__unit__direction(unit=u, direction=:in)
                if c_in in commodity_group__commodity(commodity_group=cg_in);
                    init=0
                )
    )
end


"""
    constraint_max_cum_in_flow_bound(m::Model, flow)

Set upperbound `max_cum_in_flow_bound `to the cumulated inflow of
`commodity_group cg` into a `unit_group ug`
if `max_cum_in_flow_bound` exists for the combination of `cg` and `ug`.
"""
function constraint_max_cum_in_flow_bound(m::Model, flow)
    @butcher @constraint(
        m,
        [
            ug in unit_group(),
            cg in commodity_group();
            max_cum_in_flow_bound(unit_group=ug, commodity_group=cg) != nothing
        ],
        + reduce(
            +,
            flow[c, n, u, :in, t]
            for (c, n, u) in commodity__node__unit__direction(direction=:in), t=1:number_of_timesteps(time=:timer)
            if u in unit_group__unit(unit_group=ug) && c in commodity_group__commodity(commodity_group=cg);
            init=0
        )
        <=
        + max_cum_in_flow_bound(unit_group=ug, commodity_group=cg)
    )
end


"""
    constraint_nodal_balance(m::Model, flow, trans)

Enforce balance of all commodity flows from and to a node.
"""
function constraint_nodal_balance(m::Model, state, flow, trans)
    @butcher for (c,n) in commodity__node(), t=1:number_of_timesteps(time=:timer)
        @constraint(
            m,
            # Change in the state commodity content
            + ( state_commodity_content(commodity=c, node=n) != nothing &&
                state_commodity_content(commodity=c, node=n)
                    * (state[c, n, t] - state[c, n, t-1])
                )
            ==
            # Commodity state discharge and diffusion
            + ( state_commodity_content(commodity=c, node=n) != nothing &&
                # Commodity self-discharge
                - ( state_commodity_discharge_rate(commodity=c, node=n) != nothing &&
                    state_commodity_discharge_rate(commodity=c, node=n)
                        * state[c, n, t]
                    )
                # Commodity diffusion between nodes
                # Diffusion into this node
                + reduce(+,
                    state_commodity_diffusion_rate(commodity=c, node1=nn, node2=n)
                    * state[c, nn, t]
                    for nn in commodity__node__node(commodity=c, node2=n);
                        init=0
                    )
                    # Diffusion from this node
                - reduce(+,
                    state_commodity_diffusion_rate(commodity=c, node1=n, node2=nn)
                    * state[c, n ,t]
                    for nn in commodity__node__node(commodity=c, node1=n);
                        init=0
                    )
                )
            # Demand for the commodity
            - ( demand(commodity=c, node=n, t=t) != nothing &&
                demand(commodity=c, node=n, t=t)
                )
            # Output of units into this node, and their input from this node
            + reduce(+,
                flow[c, n, u, :out, t]
                for u in commodity__node__unit__direction(commodity=c, node=n, direction=:out);
                    init=0
                )
            - reduce(+,
                flow[c, n, u, :in, t]
                for u in commodity__node__unit__direction(commodity=c, node=n, direction=:in);
                    init=0
                )
            # Transfer of commodities between nodes
            - reduce(+,
                trans[conn, n, t]
                for conn in connection__node(node=n);
                    init=0
                )
        )
    end
end


## Script
# Export contents of database into the current session
db_url = "sqlite:///examples/data/testsystemA4.sqlite"
JuMP_all_out(db_url)

# Init model
m = Model(with_optimizer(Clp.Optimizer))

# Create decision variables
state = generate_variable_state(m)
flow = generate_variable_flow(m)
trans = generate_variable_trans(m)

# Bounds for state variables
# These should be integrated into generate_variable_state, if only I knew how
# Also, the initial value t[0] is not constrained at the moment
for (c, n) in commodity__node(), t=1:number_of_timesteps(time=:timer)
    state_lower_bound(commodity=c, node=n, t=t) != nothing && set_lower_bound(state[c, n, t], state_lower_bound(commodity=c, node=n, t=t))
    state_upper_bound(commodity=c, node=n, t=t) != nothing && set_upper_bound(state[c, n, t], state_upper_bound(commodity=c, node=n, t=t))
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

# Cyclic node state bounds
constraint_node_state_cyclic_bound(m, state)

# Absolute bounds on commodities
constraint_max_cum_in_flow_bound(m, flow)

# needed: set/group of unitgroup CHP and Gasplant

# Run model
optimize!(m)
status = termination_status(m)
if status == MOI.OPTIMAL
    db_url_out = db_url
    JuMP_results_to_spine_db!(db_url_out, db_url; state=state, flow=flow)
end
