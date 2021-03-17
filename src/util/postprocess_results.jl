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
    postprocess_results!(m::Model)

Perform calculations on the model outputs and save them to the ext.values dict.
bases on contents of report__output
"""
function postprocess_results!(m::Model)
    outputs = [Symbol(x[2]) for x in report__output()]
    fns! = 
        Dict(
            :connection_avg_throughflow => save_connection_avg_throughflow!,
            :connection_avg_intact_throughflow => save_connection_avg_intact_throughflow!
        )
    for (_report, output) in report__output()
        fn! = get(fns!, output.name, nothing)
        fn! === nothing || fn!(m)
    end
end

function save_connection_avg_throughflow!(m::Model)
    @fetch connection_flow = m.ext[:variables]
    m.ext[:values][:connection_avg_throughflow] = Dict(
        (connection=conn, stochastic_path=stochastic_path, t=t) =>
            0.5 * (
                +sum(
                    JuMP.value(connection_flow[conn, n_to, d, s, t])
                    for
                    (conn, n_to, d, s, t) in connection_flow_indices(
                        m;
                        connection=conn,
                        node=n_to,
                        direction=direction(:to_node),
                        stochastic_scenario=stochastic_path,
                        t=t_in_t(m; t_long=t),
                    )
                ) - sum(
                    JuMP.value(connection_flow[conn, n_to, d, s, t])
                    for
                    (conn, n_to, d, s, t) in connection_flow_indices(
                        m;
                        connection=conn,
                        node=n_to,
                        direction=direction(:from_node),
                        stochastic_scenario=stochastic_path,
                        t=t_in_t(m; t_long=t),
                    )
                ) - sum(
                    JuMP.value(connection_flow[conn, n_from, d, s, t])
                    for
                    (conn, n_from, d, s, t) in connection_flow_indices(
                        m;
                        connection=conn,
                        node=n_from,
                        direction=direction(:to_node),
                        stochastic_scenario=stochastic_path,
                        t=t_in_t(m; t_long=t),
                    )
                ) + sum(
                    JuMP.value(connection_flow[conn, n_from, d, s, t])
                    for
                    (conn, n_from, d, s, t) in connection_flow_indices(
                        m;
                        connection=conn,
                        node=n_from,
                        direction=direction(:from_node),
                        stochastic_scenario=stochastic_path,
                        t=t_in_t(m; t_long=t),
                    )
                )
            )
        for
        (conn, n_from, n_to) in (
            (
                conn,
                first(connection__from_node(connection=conn, direction=anything)),
                last(connection__from_node(connection=conn, direction=anything)),
            ) for conn in connection(connection_monitored=true, has_ptdf=true)
        )  # NOTE: we always assume that the second (last) node in `connection__from_node` is the 'to' node
        for
        t in t_lowest_resolution(x.t for x in connection_flow_indices(m; connection=conn, node=[n_from, n_to]))
        for
        stochastic_path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in _connection_avg_throughflow_indices(m, conn, n_from, n_to, t)
        ))
    )
end

function _connection_avg_throughflow_indices(m, conn, n_from, n_to, t)
    Iterators.flatten((
        connection_flow_indices(m; connection=conn, node=n_to, direction=direction(:to_node), t=t_in_t(m; t_long=t)),
        connection_flow_indices(
            m;
            connection=conn,
            node=n_from,
            direction=direction(:from_node),
            t=t_in_t(m; t_long=t),
        ),
    ))
end


function save_connection_avg_intact_throughflow!(m::Model)
    @fetch connection_intact_flow = m.ext[:variables]
    m.ext[:values][:connection_avg_intact_throughflow] = Dict(
        (connection=conn, stochastic_path=stochastic_path, t=t) =>
            0.5 * (
                +sum(
                    JuMP.value(connection_intact_flow[conn, n_to, d, s, t])
                    for
                    (conn, n_to, d, s, t) in connection_intact_flow_indices(
                        m;
                        connection=conn,
                        node=n_to,
                        direction=direction(:to_node),
                        stochastic_scenario=stochastic_path,
                        t=t_in_t(m; t_long=t),
                    )
                ) - sum(
                    JuMP.value(connection_intact_flow[conn, n_to, d, s, t])
                    for
                    (conn, n_to, d, s, t) in connection_intact_flow_indices(
                        m;
                        connection=conn,
                        node=n_to,
                        direction=direction(:from_node),
                        stochastic_scenario=stochastic_path,
                        t=t_in_t(m; t_long=t),
                    )
                ) - sum(
                    JuMP.value(connection_intact_flow[conn, n_from, d, s, t])
                    for
                    (conn, n_from, d, s, t) in connection_intact_flow_indices(
                        m;
                        connection=conn,
                        node=n_from,
                        direction=direction(:to_node),
                        stochastic_scenario=stochastic_path,
                        t=t_in_t(m; t_long=t),
                    )
                ) + sum(
                    JuMP.value(connection_intact_flow[conn, n_from, d, s, t])
                    for
                    (conn, n_from, d, s, t) in connection_intact_flow_indices(
                        m;
                        connection=conn,
                        node=n_from,
                        direction=direction(:from_node),
                        stochastic_scenario=stochastic_path,
                        t=t_in_t(m; t_long=t),
                    )
                )
            )
        for
        (conn, n_from, n_to) in (
            (
                conn,
                first(connection__from_node(connection=conn, direction=anything)),
                last(connection__from_node(connection=conn, direction=anything)),
            ) for conn in connection(connection_monitored=true, has_ptdf=true)
        )  # NOTE: we always assume that the second (last) node in `connection__from_node` is the 'to' node
        for
        t in t_lowest_resolution(x.t for x in connection_intact_flow_indices(m; connection=conn, node=[n_from, n_to]))
        for
        stochastic_path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in _connection_avg_intact_throughflow_indices(m, conn, n_from, n_to, t)
        ))
    )
end

function _connection_avg_intact_throughflow_indices(m, conn, n_from, n_to, t)
    Iterators.flatten((
        connection_intact_flow_indices(m; connection=conn, node=n_to, direction=direction(:to_node), t=t_in_t(m; t_long=t)),
        connection_intact_flow_indices(
            m;
            connection=conn,
            node=n_from,
            direction=direction(:from_node),
            t=t_in_t(m; t_long=t),
        ),
    ))
end