### 0. Gas specific variables

"""
    variable_pressure(m::Model)

Create the `pressure` variable for the model `m`.

This variable represents the pressure at a *node* and within a certain *time slice*.

"""
function variable_pressure(m::Model)
    KeyType = NamedTuple{(:node, :t),Tuple{Object,TimeSlice}}
    m.ext[:variables][:pressure] = Dict{KeyType,Any}(
        (node=n, t=t) => @variable(
            m, base_name="pressure[$n, $(t.JuMP_name)]", lower_bound=min_pressure(node=n), upper_bound=max_pressure(node=n)
        )
        for (n, t) in pressure_indices()
    )
end

"""
    pressure_indices(
        node=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `pressure` variable.
The keyword arguments act as filters for each dimension.
"""
function pressure_indices(;node=anything, t=anything)
    [
        (node=n, t=t1)
        for (n,blk) in node__temporal_block(
            node=node, _compact=false
        )
            for t1 in time_slice(temporal_block=blk, t=t)
                if n in indices(max_pressure)
    ]
end






"""
    constraint_fix_pressure_point(m::Model)

Outer approximation of the non-linear terms.
"""
function constraint_fix_pressure_point(m::Model)
    @fetch pressure,trans,binary_trans = m.ext[:variables]
    constr_dict = m.ext[:constraints][:fix_pressure_point] = Dict()
    for (conn, n_orig, n_dest) in indices(K1)
        for (conn,n_orig,c,d_from,t) in trans_indices(connection=conn,node=n_orig,direction=:from_node)
            for j = 1:length(K1(connection=conn,node1=n_orig,node2=n_dest))
                if K1(connection=conn,node1=n_orig,node2=n_dest,i=j) != 0
                    constr_dict[conn, n_orig, n_dest, j, t] = @constraint(
                        m,
                        (trans[conn,n_orig,c,d_from,t] + trans[conn,n_dest,c,Object("to_node"),t])/2 ##### TO DO from node, to node???? for all segments??????
                        <=
                        + K1(connection=conn,node1=n_orig,node2=n_dest,i=j) * pressure[n_orig,t] - K0(connection=conn,node1=n_orig,node2=n_dest,i=j)* pressure[n_dest,t]
                        + bigM(model=:instance)* (1-binary_trans[conn, n_dest, Object("to_node"), t])
                    )
                end
            end
        end
    end
end


"""
    constraint_compression_ratio(m::Model)

Constraint for compressor pipelines.
"""
function constraint_compression_ratio(m::Model)
    @fetch pressure = m.ext[:variables]
    constr_dict = m.ext[:constraints][:compression_ratio] = Dict()
    for (conn, n_orig, n_dest) in indices(compression_factor)
        for (n_orig,t) in pressure_indices(node=n_orig)
            constr_dict[conn, n_orig, n_dest, t] = @constraint(
                m,
                pressure[n_dest,t]
                <=
                compression_factor(connection = conn,node1=n_orig,node2=n_dest) * pressure[n_orig,t]
                )
        end
    end
end


"""
    constraint_storage_line_pack(m::Model)

Constraint for line storage dependent on line pack.
"""
function constraint_storage_line_pack(m::Model)
    @fetch stor_state = m.ext[:variables]
    @fetch pressure = m.ext[:variables]
    constr_dict = m.ext[:constraints][:storage_line_pack] = Dict()
    for (stor,conn) in storage__connection()
        for conn in indices(linepack_constant;connection=conn)
            for (n_orig,n_dest) in connection__from_node__to_node(connection=conn)
                for (conn,n,c,d,t) in trans_indices(connection=conn)
                    constr_dict[conn, stor, t] = @constraint(
                        m,
                        stor_state[stor,c,t]
                        ==
                        linepack_constant(connection=conn)*0.5*(pressure[n_orig,t]+pressure[n_dest,t])
                        )
                end
                end
        end
    end
end

#### TODO make this one generic
"""
    constraint_stor_state(m::Model)

Balance for storage level.
"""
function constraint_init_stor_state(m::Model)
    @fetch stor_state,flow,trans= m.ext[:variables]
    constr_dict = m.ext[:constraints][:init_stor_state] = Dict()
    for (stor, c, t_after) in stor_state_indices()
        if t_after == time_slice()[1]
            constr_dict[stor, c, t_after] = @constraint(
                m,
                + stor_state[stor, c, t_after]
                    * state_coeff(storage=stor)
                     / duration(t_after)
                ==
                stor_state_init(storage=stor)
                - reduce(
                    +,
                    flow[u, n, c_, d, t_] * stor_unit_discharg_eff(storage=stor, unit=u)
                    for (u, n, c_, d, t_) in flow_indices(
                        unit=[u1 for (stor1, u1) in indices(stor_unit_discharg_eff; storage=stor)],
                        commodity=c,
                        direction=:to_node,
                        t=t_after
                    );
                    init=0
                )
                + reduce(
                    +,
                    flow[u, n, c_, d, t_] * stor_unit_charg_eff(storage=stor, unit=u)
                    for (u, n, c_, d, t_) in flow_indices(
                        unit=[u1 for (stor1, u1) in indices(stor_unit_charg_eff; storage=stor)],
                        commodity=c,
                        direction=:from_node,
                        t=t_after
                    );
                    init=0
                )
                - reduce(
                    +,
                    trans[conn, n, c_, d, t_] * stor_conn_discharg_eff(storage=stor, connection=conn)
                    for (conn, n, c_, d, t_) in trans_indices(
                        connection=[conn1 for (stor1, conn1) in indices(stor_conn_discharg_eff; storage=stor)],
                        commodity=c,
                        direction=:to_node,
                        t=t_after
                    );
                    init=0
                )
                + reduce(
                    +,
                    trans[conn, n, c_, d, t_] * stor_conn_charg_eff(storage=stor, connection=conn)
                    for (conn, n, c_, d, t_) in trans_indices(
                        connection=[conn1 for (stor1, conn1) in indices(stor_conn_charg_eff; storage=stor)],
                        commodity=c,
                        direction=:from_node,
                        t=t_after
                    );
                    init=0
                )
                )
        end
        if t_after == time_slice()[end]
            constr_dict[stor, c, t_after] = @constraint(
                m,
                + stor_state[stor, c, t_after]
                    * state_coeff(storage=stor)
                     / duration(t_after)
                >=
                stor_state_init(storage=stor)
                )
        end
    end
end

"""
    constraint_gas_line_pack_capacity(m::Model)

This constraint is needed to force uni-directional flow
"""
function constraint_trans_gas_capacity(m::Model)
    @fetch trans,binary_trans = m.ext[:variables]
    constr_dict = m.ext[:constraints][:trans_gas_capacity] = Dict()
    for (conn, n, c, d, t) in var_trans_indices(commodity=Object("Gas"),direction=Object("to_node"))
            constr_dict[conn, n, t] = @constraint(
                m,
                (
                    trans[conn, n, c, d, t]
                    +  reduce(
                    +,
                    trans[conn1, n1, c1,  d1, t1]
                        for (conn1,n1,c1,d1,t1) in var_trans_indices(connection=conn,commodity=c,t=t)
                            if d1 != d && n1 != n
                        )
                ) /2
                <=
                + bigM(model=:instance)
                * binary_trans[conn, n, d, t]
            )
    end
end

### 2. El specific variables
"""
    variable_theta(m::Model)

Create the `theta` variable for the model `m`.

This variable represents the theta at a *node* and within a certain *time slice*.

"""
function variable_theta(m::Model)
    KeyType = NamedTuple{(:node, :t),Tuple{Object,TimeSlice}}
    m.ext[:variables][:theta] = Dict{KeyType,Any}(
        (node=n, t=t) => @variable(
            m, base_name="theta[$n, $(t.JuMP_name)]", lower_bound=min_voltage_angle(node=n), upper_bound=max_voltage_angle(node=n)
        )
        for (n, t) in theta_indices()
    )
end

"""
    theta_indices(
        node=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `theta` variable.
The keyword arguments act as filters for each dimension.
"""
function theta_indices(;node=anything, t=anything)
    [
        (node=n, t=t1)
        for (n,blk) in node__temporal_block(
            node=node, _compact=false
        )
            for t1 in time_slice(temporal_block=blk, t=t)
                if n in indices(max_voltage_angle)
    ]
end

### 3. El specific constraints
"""
    constraint_voltage_angle(m::Model)

Outer approximation of the non-linear terms.
"""
function constraint_ref_node(m::Model)
    @fetch theta = m.ext[:variables]
    constr_dict = m.ext[:constraints][:ref_node] = Dict()
    n = Object("node_1")
        for t in time_slice()
            constr_dict[n,t] = @constraint(
                m,
                theta[n,t]
                ==
                0
            )
        end
end


"""
    constraint_voltage_angle(m::Model)

Outer approximation of the non-linear terms.
"""
function constraint_voltage_angle(m::Model)
    @fetch theta = m.ext[:variables]
    @fetch trans = m.ext[:variables]
    constr_dict = m.ext[:constraints][:voltage_angle] = Dict()
    for conn in indices(line_susceptance)
        for (conn,n_from,c,d_from,t) in var_trans_indices(connection=conn,direction=:from_node)
            for (conn,n_to,c,d_to,t)  in var_trans_indices(connection=conn,commodity=c,direction=:to_node,t=t)
                if n_to != n_from
                    constr_dict[conn,n_from,t] = @constraint(
                        m,
                            trans[conn,n_from,c,d_from,t]
                            -
                                trans[conn,n_to,c,d_from,t]
                        ==
                        1/line_susceptance(connection=conn)
                        * 250
                        * (theta[n_from,t]
                            -
                                    theta[n_to,t])
                    )
                end
            end
        end
    end
end


function extend_model(m::Model)
    variable_pressure(m)
    constraint_fix_pressure_point(m)
    constraint_compression_ratio(m)
    constraint_storage_line_pack(m)
    constraint_init_stor_state(m)
    constraint_trans_gas_capacity(m)
    variable_theta(m)
    constraint_ref_node(m)
    constraint_voltage_angle(m)
end
