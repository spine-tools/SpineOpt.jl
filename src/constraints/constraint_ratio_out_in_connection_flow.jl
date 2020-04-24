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
    add_constraint_ratio_out_in_connection_flow!(m, ratio_out_in, sense)

Ratio of `connection_flow` variables.
"""
function add_constraint_ratio_out_in_connection_flow!(m::Model, ratio_out_in, sense)
    @fetch connection_flow = m.ext[:variables]
    cons = m.ext[:constraints][ratio_out_in.name] = Dict()
    for (conn, n_out, n_in) in indices(ratio_out_in)
        for t in t_lowest_resolution(map(x -> x.t, connection_flow_indices(connection=conn, node=[n_out, n_in])))
            for s in map(x -> x.stochastic_scenario, connection_flow_indices(connection=conn, node=[n_out, n_in], t=t))
                con = cons[conn, n_out, n_in, s, t] = sense_constraint( # TODO: Stochastic path indexing required due to multiple `nodes`
                    m,
                    + reduce(
                        +,
                        connection_flow[conn_, n_out_, d, s, t_] * duration(t_)
                        for (conn_, n_out_, d, s, t_) in connection_flow_indices(
                            connection=conn, node=n_out, direction=direction(:to_node), stochastic_scenario=s, t=t_in_t(t_long=t)
                        );
                        init=0
                    ),
                    sense,
                    + ratio_out_in[(connection=conn, node1=n_out, node2=n_in, t=t)] # TODO: Stochastic parameters, what the heck are this one's dimensions going to be?
                    * reduce(
                        +,
                        connection_flow[conn_, n_in_, d, s, t_]
                        * overlap_duration(t_, t - connection_flow_delay(connection=conn, node1=n_out, node2=n_in))
                        for (conn_, n_in_, d, s, t_) in connection_flow_indices(
                            connection=conn,
                            node=n_in,
                            direction=direction(:from_node),
                            stochastic_scenario=s,
                            t=to_time_slice(t - connection_flow_delay(connection=conn, node1=n_out, node2=n_in, t=t))
                        );
                        init=0
                    )
                )
            end
        end
    end
end

add_constraint_fix_ratio_out_in_connection_flow!(m::Model) = add_constraint_ratio_out_in_connection_flow!(m, fix_ratio_out_in_connection_flow, ==)
add_constraint_max_ratio_out_in_connection_flow!(m::Model) = add_constraint_ratio_out_in_connection_flow!(m, max_ratio_out_in_connection_flow, <=)
add_constraint_min_ratio_out_in_connection_flow!(m::Model) = add_constraint_ratio_out_in_connection_flow!(m, min_ratio_out_in_connection_flow, >=)
