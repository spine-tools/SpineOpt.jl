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
    add_constraint_ratio_out_in_connection_flow!(m, ratio_out_in, sense)

Ratio of `connection_flow` variables.

Note that the `<sense>_ratio_<directions>_connection_flow` parameter uses the stochastic dimensions of the second
<direction>!
"""
function add_constraint_ratio_out_in_connection_flow!(m::Model, ratio_out_in, sense)
    @fetch connection_flow = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][ratio_out_in.name] = Dict(
        (connection=conn, node1=ng_out, node2=ng_in, stochastic_path=s, t=t) => sense_constraint(
            m,
            + expr_sum(
                + connection_flow[conn, n_out, d, s, t_short] * duration(t_short)
                for (conn, n_out, d, s, t_short) in connection_flow_indices(
                    m;
                    connection=conn,
                    node=ng_out,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            ),
            sense,
            + expr_sum(
                + connection_flow[conn, n_in, d, s, t_short]
                * ratio_out_in[
                    (connection=conn, node1=ng_out, node2=ng_in, stochastic_scenario=s, analysis_time=t0, t=t_short),
                ]
                * overlap_duration(
                    t_short,
                    t - connection_flow_delay(
                        connection=conn,
                        node1=ng_out,
                        node2=ng_in,
                        stochastic_scenario=s,
                        analysis_time=t0,
                        t=t,
                    ),
                ) for (conn, n_in, d, s, t_short) in connection_flow_indices(
                    m;
                    connection=conn,
                    node=ng_in,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=to_time_slice(
                        m;
                        t=t - connection_flow_delay(
                            connection=conn,
                            node1=ng_out,
                            node2=ng_in,
                            stochastic_scenario=s,
                            analysis_time=t0,
                            t=t,
                        ),
                    ),
                );
                init=0,
            ),
        ) for (conn, ng_out, ng_in, s, t) in constraint_ratio_out_in_connection_flow_indices(m, ratio_out_in)
    )
end

"""
    add_constraint_fix_ratio_out_in_connection_flow!(m::Model)

Call `add_constraint_ratio_out_in_connection_flow!` using the `fix_ratio_out_in_connection_flow` parameter.
"""
function add_constraint_fix_ratio_out_in_connection_flow!(m::Model)
    add_constraint_ratio_out_in_connection_flow!(m, fix_ratio_out_in_connection_flow, ==)
end

"""
    add_constraint_max_ratio_out_in_connection_flow!(m::Model)

Call `add_constraint_ratio_out_in_connection_flow!` using the `max_ratio_out_in_connection_flow` parameter.
"""
function add_constraint_max_ratio_out_in_connection_flow!(m::Model)
    add_constraint_ratio_out_in_connection_flow!(m, max_ratio_out_in_connection_flow, <=)
end

"""
    add_constraint_min_ratio_out_in_connection_flow!(m::Model)

Call `add_constraint_ratio_out_in_connection_flow!` using the `min_ratio_out_in_connection_flow` parameter.
"""
function add_constraint_min_ratio_out_in_connection_flow!(m::Model)
    add_constraint_ratio_out_in_connection_flow!(m, min_ratio_out_in_connection_flow, >=)
end

function constraint_ratio_out_in_connection_flow_indices(m::Model, ratio_out_in)
    t0 = _analysis_time(m)
    unique(
        (connection=conn, node1=n_out, node2=n_in, stochastic_path=path, t=t)
        for (conn, n_out, n_in) in indices(ratio_out_in) for t in t_lowest_resolution(
            x.t for x in connection_flow_indices(
                m;
                connection=conn,
                node=Iterators.flatten((members(n_out), members(n_in))),
            )
        ) for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario
                for ind in _constraint_ratio_out_in_connection_flow_indices(m, conn, n_out, n_in, t0, t)
            ),
        )
    )
end

"""
    constraint_ratio_out_in_connection_flow_indices_filtered(m::Model, ratio_out_in; filtering_options...)

Form the stochastic indexing Array for the `:ratio_out_in_connection_flow` constraint for the desired `ratio_out_in`.

Uses stochastic path indices due to potentially different stochastic structures between `connection_flow` variables.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ratio_out_in_connection_flow_indices_filtered(
    m::Model,
    ratio_out_in;
    connection=anything,
    node1=anything,
    node2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node1=node1, node2=node2, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_ratio_out_in_connection_flow_indices(m, ratio_out_in))
end

"""
    _constraint_ratio_out_in_connection_flow_indices(connection, node_out, node_in, t0, t)

Gather the `connection_flow` variiable indices for `add_constraint_ratio_out_in_connection_flow!`.
"""
function _constraint_ratio_out_in_connection_flow_indices(m, connection, node_group_out, node_group_in, t0, t)
    Iterators.flatten((
        connection_flow_indices(
            m;
            connection=connection,
            node=node_group_out,
            direction=direction(:to_node),
            t=t_in_t(m; t_long=t),
        ),
        (connection=conn, node=n_in, direction=d, stochastic_scenario=s, t=t)
        for (conn, n_in, d, s, t1) in connection_flow_indices(
            m;
            connection=connection,
            node=node_group_in,
            direction=direction(:from_node),
            t=t_in_t(m; t_long=t),
        ) for (conn, n_in, d, s, t) in connection_flow_indices(
            m;
            connection=conn,
            node=node_group_in,
            direction=d,
            t=to_time_slice(
                m;
                t=t - connection_flow_delay(
                    connection=conn,
                    node1=node_group_out,
                    node2=node_group_in,
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t1,
                ),
            ),
        )  # `from_node` `connection_flow`s with potential `connection_flow_delay`
    ))
end
