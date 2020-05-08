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
    constraint_ratio_out_in_connection_flow_indices(ratio_out_in)

Forms the stochastic index set for the `:ratio_out_in_connection_flow` constraint
for the desired `ratio_out_in`. Uses stochastic path indices due to potentially
different stochastic structures between `connection_flow` variables.
"""
function constraint_ratio_out_in_connection_flow_indices(ratio_out_in)
    ratio_out_in_connection_flow_indices = []
    for (conn, n_out, n_in) in indices(ratio_out_in)
        for t in t_lowest_resolution(x.t for x in connection_flow_indices(connection=conn, node=[n_out, n_in]))
            # `to_node` `connection_flow`s
            active_scenarios = connection_flow_indices_rc(
                connection=conn, node=n_out, direction=direction(:to_node), t=t_in_t(t_long=t), _compact=true
            )
            # `from_node` `connection_flow`s with potential `connection_flow_delay`
            append!(
                active_scenarios,
                connection_flow_indices_rc(
                    connection=conn,
                    node=n_in,
                    direction=direction(:from_node),
                    t=to_time_slice(t - connection_flow_delay(connection=conn, node1=n_out, node2=n_in, t=t)),
                    _compact=true
                )
            )
            # Find stochastic paths for `active_scenarios`
            unique!(active_scenarios)
            for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
                push!(
                    ratio_out_in_connection_flow_indices,
                    (connection=conn, node1=n_out, node2=n_in, stochastic_path=path, t=t)
                )
            end
        end
    end
    return unique!(ratio_out_in_connection_flow_indices)
end


"""
    add_constraint_ratio_out_in_connection_flow!(m, ratio_out_in, sense)

Ratio of `connection_flow` variables.
"""
function add_constraint_ratio_out_in_connection_flow!(m::Model, ratio_out_in, sense)
    @fetch connection_flow = m.ext[:variables]
    cons = m.ext[:constraints][ratio_out_in.name] = Dict()
    for (conn, n_out, n_in, stochastic_path, t) in constraint_ratio_out_in_connection_flow_indices(ratio_out_in)
        con = cons[conn, n_out, n_in, t] = sense_constraint(
            m,
            + expr_sum(
                + connection_flow[conn, n_out, d, s, t_short] * duration(t_short)
                for (conn, n_out, d, s, t_short) in connection_flow_indices(
                    connection=conn, node=n_out, direction=direction(:to_node), stochastic_scenario=stochastic_path, t=t_in_t(t_long=t)
                );
                init=0
            ),
            sense,
            + ratio_out_in[(connection=conn, node1=n_out, node2=n_in, t=t)]
            * expr_sum(
                + connection_flow[conn, n_in, d, s, t_short]
                * overlap_duration(t_short, t - connection_flow_delay(connection=conn, node1=n_out, node2=n_in))
                for (conn, n_in, d, s, t_short) in connection_flow_indices(
                    connection=conn,
                    node=n_in,
                    direction=direction(:from_node),
                    stochastic_scenario=stochastic_path,
                    t=to_time_slice(t - connection_flow_delay(connection=conn, node1=n_out, node2=n_in, t=t))
                );
                init=0
            )
        )
    end
end

add_constraint_fix_ratio_out_in_connection_flow!(m::Model) = add_constraint_ratio_out_in_connection_flow!(m, fix_ratio_out_in_connection_flow, ==)
add_constraint_max_ratio_out_in_connection_flow!(m::Model) = add_constraint_ratio_out_in_connection_flow!(m, max_ratio_out_in_connection_flow, <=)
add_constraint_min_ratio_out_in_connection_flow!(m::Model) = add_constraint_ratio_out_in_connection_flow!(m, min_ratio_out_in_connection_flow, >=)
