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
    constraint_connection_flow_capacity_indices()

Forms the stochastic index set for the `:connection_flow_capacity` constraint.
Uses stochastic path indices due to potentially different stochastic structures
between `connection_flow` variables.
"""
function constraint_connection_flow_capacity_indices()
    connection_flow_capacity_indices = []
    for (conn, n, d) in indices(connection_capacity)
        for t in t_lowest_resolution(x.t for x in connection_flow_indices(connection=conn,node=n,direction=d))
            # Ensure type stability
            active_scenarios = Array{Object,1}()
            # Constrained `connection_flow`
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    connection_flow_indices(connection=conn, node=n, direction=d, t=t)
                )
            )
            # Find stochastic paths for `active_scenarios`
            unique!(active_scenarios)
            for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
                push!(
                    connection_flow_capacity_indices,
                    (connection=conn, node=n, direction=d, stochastic_path=path, t=t)
                )
            end
        end
    end
    return unique!(connection_flow_capacity_indices)
end

"""
    add_constraint_connection_flow_capacity!(m::Model)

Limit the maximum in/out `connection_flow` of a `connection` for all `connection_flow_capacity` indices.
Check if `connection_conv_cap_to_flow` is defined.
"""
function add_constraint_connection_flow_capacity!(m::Model)
    @fetch connection_flow = m.ext[:variables]
    cons = m.ext[:constraints][:connection_flow_capacity] = Dict()
    for (conn, ng, d, s, t) in constraint_connection_flow_capacity_indices()
        cons[conn, ng, d, s, t] = @constraint(
            m,
            + expr_sum(
                connection_flow[conn, n, d, s, t] * duration(t)
                    for (conn, n, d, s, t) in connection_flow_indices(
                        connection=conn, direction=d, node=ng, stochastic_scenario=s, t=t_in_t(t_long=t));
                init=0
            )
            <=
            + connection_capacity[(connection=conn, node=ng, direction=d, stochastic_scenario=s, t=t)]
            * connection_availability_factor[(connection=conn, stochastic_scenario=s, t=t)]
            * connection_conv_cap_to_flow[(connection=conn, node=ng, direction=d, stochastic_scenario=s, t=t)]
            + expr_sum(
                connection_flow[conn, n, d_reverse, s, t] * duration(t)
                    for (conn, n, d_reverse, s, t) in connection_flow_indices(
                        connection=conn, node=ng, stochastic_scenario=s, t=t_in_t(t_long=t)
                        )
                            if d_reverse != d && is_reserve_node(node=n) == :is_reserve_node_false;
                init=0
            )
        )
    end
end
