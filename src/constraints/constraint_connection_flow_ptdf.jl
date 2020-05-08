#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
"""
    constraint_connection_flow_ptdf_indices()

Forms the stochastic index set for the `:connection_flow_lodf` constraint.
Uses stochastic path indices due to potentially different stochastic structures
between `connection_flow` and `node_injection` variables?
"""
function constraint_connection_flow_ptdf_indices()
    connection_flow_ptdf_indices = []
    for conn in connection(connection_monitored=:value_true, has_ptdf=true)
        node_direction = last(connection__from_node(connection=conn)) # NOTE: always assume that the second (last) node in `connection__from_node` is the 'to' node
        n_to = node_direction.node
        direction = node_direction.direction
        for t in time_slice(temporal_block=node__temporal_block(node=n_to))
            # `n_to`
            active_scenarios = connection_flow_indices_rc(
                connection=conn, node=n_to, direction=direction, t=t, _compact=true
            )
            # `n_inj`
            for (conn, n_inj) in indices(ptdf; connection=conn)
                append!(
                    active_scenarios,
                    node_stochastic_time_indices_rc(node=n_inj, t=t, _compact=true)
                )
            end
            # Find stochastic paths for `active_scenarios`
            unique!(active_scenarios)
            for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
                push!(
                    connection_flow_ptdf_indices,
                    (connection=conn, node=n_to, stochastic_scenario=path, t=t)
                )
            end
        end
    end
    return unique!(connection_flow_ptdf_indices)
end


"""
    add_constraint_connection_flow_ptdf(m::Model)

For connection networks with monitored and has_ptdf set to true, set the steady state flow based on PTDFs
"""
function add_constraint_connection_flow_ptdf!(m::Model)
    @fetch connection_flow, node_injection = m.ext[:variables]
    constr_dict = m.ext[:constraints][:flow_ptdf] = Dict()
    for (conn, n_to, stochastic_path, t) in constraint_connection_flow_ptdf_indices()
        constr_dict[conn, n_to, stochastic_path, t] = @constraint(
            m,
            + expr_sum(
                + get(connection_flow, (conn, n_to, direction(:to_node), s, t), 0)
                - get(connection_flow, (conn, n_to, direction(:from_node), s, t), 0)
                for s in stochastic_path
            )
            ==
            + expr_sum(
                ptdf(connection=conn, node=n) * node_injection[n, s, t]
                for (conn, n) in indices(ptdf; connection=conn)
                for (n, s, t) in node_injection_indices(
                    node=n, stochastic_scenario=stochastic_path, t=t
                );
                init=0
            )
        )
    end
end
