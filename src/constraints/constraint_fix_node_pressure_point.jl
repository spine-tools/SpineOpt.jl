#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
"""
    constraint_fix_node_pressure_point(m::Model)

Outer approximation of the non-linear terms.
#Linear apprioximation around fixed pressure points
"""
function add_constraint_fix_node_pressure_point!(m::Model)
    @fetch node_pressure, connection_flow, binary_gas_connection_flow = m.ext[:spineopt][:variables]
    t0 = _analysis_time(m)
    m.ext[:spineopt][:constraints][:fix_node_pressure_point] = Dict(
        (connection=conn, node1=n_orig, node2=n_dest, stochastic_scenario=s, t=t, i=j) => @constraint(
            m,
            (
                expr_sum(
                    connection_flow[conn, n_orig, d, s, t] for (conn, n_orig, d, s, t) in connection_flow_indices(
                        m;
                        connection=conn,
                        node=n_orig,
                        stochastic_scenario=s,
                        direction=direction(:from_node),
                        t=t_in_t(m; t_long=t),
                    );
                    init=0
                ) + expr_sum(
                    connection_flow[conn, n_dest, d, s, t] for (conn, n_dest, d, s, t) in connection_flow_indices(
                        m;
                        connection=conn,
                        node=n_dest,
                        stochastic_scenario=s,
                        direction=direction(:to_node),
                        t=t_in_t(m; t_long=t),
                    );
                    init=0
                )
            )
            / 2
            <=
            0
            + (fixed_pressure_constant_1[
                (connection=conn, node1=n_orig, node2=n_dest, i=j, stochastic_scenario=s, analysis_time=t0, t=t),
            ]) * expr_sum(
                node_pressure[n_orig, s, t] for (n_orig, s, t) in node_pressure_indices(
                    m;
                    node=n_orig,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0
            )
            - (fixed_pressure_constant_0[
                (connection=conn, node1=n_orig, node2=n_dest, i=j, stochastic_scenario=s, analysis_time=t0, t=t),
            ]) * expr_sum(
                node_pressure[n_dest, s, t] for (n_dest, s, t) in node_pressure_indices(
                    m;
                    node=n_dest,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0
            )            
            + big_m(model=m.ext[:spineopt][:instance]) * (expr_sum(
                1 - binary_gas_connection_flow[conn, n_dest, direction(:to_node), s, t]
                for (conn, n_dest, d, s, t) in connection_flow_indices(
                    m;
                    connection=conn,
                    node=n_dest,
                    stochastic_scenario=s,
                    direction=direction(:to_node),
                    t=t_in_t(m; t_long=t),
                );
                init=0
            ))
        ) for (conn, n_orig, n_dest, s, t) in constraint_connection_flow_gas_capacity_indices(m)
        for j = 1:length(fixed_pressure_constant_1(connection=conn, node1=n_orig, node2=n_dest))
            if fixed_pressure_constant_1(connection=conn, node1=n_orig, node2=n_dest, i=j) != 0
    )
end
