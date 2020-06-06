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
    constraint_connection_flow_lodf_indices()

Forms the stochastic index set for the `:connection_flow_lodf` constraint.
Uses stochastic path indices due to potentially different stochastic structures
between `connection_flow` variables.
"""
function constraint_connection_flow_lodf_indices()
    connection_flow_lodf_indices = []
    for (conn_cont, conn_mon) in indices(lodf)
        involved_t = (
            x.t
            for conn in (conn_cont, conn_mon)
            for x in connection_flow_indices(; connection=conn, last(connection__from_node(connection=conn))...)
        )
        for t in t_lowest_resolution(involved_t)
            # Ensure type stability
            active_scenarios = Array{Object,1}()
            # Monitored connection
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    connection_flow_indices(
                        connection=conn_mon,
                        last(connection__from_node(connection=conn_mon))...,
                        t=t_in_t(t_long=t)
                    ) # NOTE: always assume the second (last) node in `connection__from_node` is the 'to' node
                )
            )
            # Excess flow due to outage on contingency connection
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    connection_flow_indices(
                        connection=conn_cont,
                        last(connection__from_node(connection=conn_cont))...,
                        t=t_in_t(t_long=t),
                    ) # NOTE: always assume the second (last) node in `connection__from_node` is the 'to' node
                )
            )
            # Find stochastic paths for `active_scenarios`
            unique!(active_scenarios)
            for path in active_stochastic_paths(active_scenarios)
                push!(
                    connection_flow_lodf_indices,
                    (connection1=conn_cont, connection2=conn_mon, stochastic_path=path, t=t)
                )
            end
        end
    end
    return unique!(connection_flow_lodf_indices)
end


"""
    add_constraint_connection_flow_lodf!(m::Model)

Limit the post contingency flow on monitored connection mon to conn_emergency_capacity upon outage of connection cont.
"""
function add_constraint_connection_flow_lodf!(m::Model)
    @fetch connection_flow = m.ext[:variables]
    cons = m.ext[:constraints][:connection_flow_lodf] = Dict()
    for (conn_cont, conn_mon, stochastic_path, t) in constraint_connection_flow_lodf_indices()
        cons[conn_cont, conn_mon, stochastic_path, t] = @constraint(
            m,
            - 1
            <=
            (
                # flow in monitored connection
                + expr_sum(
                    + connection_flow[conn_mon, n_mon_to, direction(:to_node), s, t_short]
                    - connection_flow[conn_mon, n_mon_to, direction(:from_node), s, t_short]
                    for (conn_mon, n_mon_to, d, t_short) in connection_flow_indices(;
                        connection=conn_mon, 
                        last(connection__from_node(connection=conn_mon))...,
                        stochastic_scenario=stochastic_path,
                        t=t_in_t(t_long=t)
                    ); # NOTE: always assume the second (last) node in `connection__from_node` is the 'to' node
                    init=0
                )
                # excess flow due to outage on contingency connection
                + lodf(connection1=conn_cont, connection2=conn_mon)
                * expr_sum(
                    + connection_flow[conn_cont, n_cont_to, direction(:to_node), s, t_short]
                    - connection_flow[conn_cont, n_cont_to, direction(:from_node), s, t_short]
                    for (conn_cont, n_cont_to, d, t_short) in connection_flow_indices(;
                        connection=conn_cont, 
                        last(connection__from_node(connection=conn_cont))...,
                        stochastic_scenario=stochastic_path,
                        t=t_in_t(t_long=t)
                    ); # NOTE: always assume the second (last) node in `connection__from_node` is the 'to' node
                    init=0
                )
            ) 
            / minimum(
                + connection_emergency_capacity[(connection=conn_mon, node=n_mon, direction=d, t=t)]
                * connection_availability_factor[(connection=conn_mon, t=t)]
                * connection_conv_cap_to_flow[(connection=conn_mon, node=n_mon, direction=d, t=t)]
                for (conn_mon, n_mon, d) in indices(connection_emergency_capacity; connection=conn_mon)
            )
            <=
            + 1
        )
    end
end
