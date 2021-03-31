function add_constraint_enforce_unitary_connection_flow!(m::Model)
    @fetch binary_connection_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:enforce_unitary_flow] = Dict()
    for (conn, n_orig, n_dest) in indices(fixed_pressure_constant_1)
        for (conn,n_orig,d_to_node,s,t) in connection_flow_indices(m;connection=conn,node=n_orig,direction=direction(:to_node))
            constr_dict[conn, n_orig, n_dest, s, t] = @constraint(
                m,
                binary_connection_flow[conn, n_orig, direction(:to_node), s,t]
                == 1 - binary_connection_flow[conn, n_dest, direction(:to_node), s,t])
        end
    end
end
#TODO
