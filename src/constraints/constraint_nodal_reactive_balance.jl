#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
# TODO: as proposed in the wiki on groups: We should be able to support
# a) node_balance for node group and NO balance for underlying node
# b) node_balance for node group AND balance for underlying node

"""
    add_constraint_nodal_balance!(m::Model)

AC OPF reactive power balance equation for nodes.
"""
function add_constraint_nodal_reactive_balance!(m::Model)
    @fetch unit_flow_reactive, connection_flow_reactive = m.ext[:spineopt].variables
    t0 = _analysis_time(m)

    m.ext[:spineopt].constraints[:nodal_reactive_balance] = Dict(
        (node=n, stochastic_scenario=s, t=t1) => @constraint(
            m,
           
            # Reactive power flows from connections (can be negative)
            + expr_sum(
                connection_flow_reactive[conn, n1, d, s, t]
                for (conn, n1, d, s, t) in connection_flow_indices(
                    m; node=n, direction=direction(:to_node), stochastic_scenario=s, t=t1
                )
                if !_issubset(
                    connection__from_node(connection=conn, direction=direction(:from_node)), _internal_nodes(n)
                );
                init=0,
            )
            # Reactive power to connections (can be negative)
            - expr_sum(
                connection_flow_reactive[conn, n1, d, s, t]
                for (conn, n1, d, s, t) in connection_flow_indices(
                    m; node=n, direction=direction(:from_node), stochastic_scenario=s, t=t1
                )
                if !_issubset(connection__to_node(connection=conn, direction=direction(:to_node)), _internal_nodes(n));
                init=0,
            )

            # Flows from units (i.e. reactive power production)
            + expr_sum(
                unit_flow_reactive[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_reactive_indices(
                    m;
                    node=n,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t1),
                    temporal_block=anything,
                );
                init=0,
            )
            # Flows to units  (i.e. reactive power absorption)
            - expr_sum(
                unit_flow_reactive[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_reactive_indices(
                    m;
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t1),
                    temporal_block=anything,
                );
                init=0,
            )
            
            == demand_reactive[
                (node=n, stochastic_scenario=s, analysis_time=t0, t=representative_time_slice(m, t1))
            ]
        )
        for n in node()
        if has_voltage(node=n) == true
        for (n, s, t1) in node_injection_indices(m; node=n)
    )
end

