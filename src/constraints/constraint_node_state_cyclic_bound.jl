"""
    constraint_node_state_cyclic_bound(m::Model, state, time_slice)

Fix the first and last modelled values of node state variables as equal.
"""
function constraint_node_state_cyclic_bound(m::Model, state, time_slice)
    @butcher for (c,n) in commodity__node()
        state_cyclic_bound(commodity=c, node=n) != nothing || continue
        @constraint(
            m,
            # Node commodity state on the first time step
            nodal_state[c, n, 0]
            ==
            # Node commodity state on the last time step
            nodal_state[c, n, number_of_timesteps(time=:timer)]
        )
    end
end
