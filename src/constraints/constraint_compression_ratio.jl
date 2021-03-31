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
    constraint_compression_ratio(m::Model)

Set a fixed compression ratio between to nodes connected through active pipeline.
"""
function add_constraint_compression_ratio!(m::Model)
    @fetch node_pressure = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:compression_ratio] = Dict(
            (connection=conn, node1=n_orig, node2=n_dest, stochastic_path=s, t=t) => @constraint(
                m,
                +expr_sum(
                    node_pressure[n_dest,s,t] * duration(t)
                    for
                    (n_dest,s,t) in node_pressure_indices(
                            m;
                            node=n_dest,
                            stochastic_scenario=s,
                            t=t_in_t(m; t_long=t),
                        );
                        init=0,
                )
                <=
                compression_factor[(connection = conn,node1=n_orig,node2=n_dest,stochastic_scenario=s, analysis_time=t0, t=t)]
                * expr_sum(
                    node_pressure[n_orig,s,t] * duration(t)
                    for
                    (n_orig,s,t) in node_pressure_indices(
                            m;
                            node=n_orig,
                            stochastic_scenario=s,
                            t=t_in_t(m; t_long=t),
                        );
                        init=0,
                    )
                ) for (conn, n_orig, n_dest, s, t) in constraint_compression_ratio_indices(m)
            )
end

"""
    constraint_compression_ratio_indices(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:compression_ratio` constraint.

Uses stochastic path indices of the `node_pressure` variables. Only the lowest resolution time slices are included,
as the `:compression_factor` is used to constrain the "average compression ratio" of the `connection`. Keyword arguments can be used to filter the resulting
"""
function constraint_compression_ratio_indices(
        m::Model;
        node1=anything,
        node2=anything,
        connection=anything,
        stochastic_path=anything,
        t=anything,
    )
    unique(
        (connection=c, node1=n1, node2=n2, stochastic_path=path, t=t)
        for (c, n1, n2) in indices(compression_factor; connection=connection, node1=node1, node2=node2)
        for t in t_lowest_resolution(time_slice(m; temporal_block=node__temporal_block(node=[members(n1)...,members(n2)...]), t=t))
        for
        path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in _constraint_compression_ratio_indices(m, n1, n2, t)
        )) if path == stochastic_path || path in stochastic_path
    )
end

"""
    _constraint_compression_ratio_indices(m, node1, node2, t)

Gather the indices of the relevant `node_pressure` variables.
"""
function _constraint_compression_ratio_indices(m, node1, node2, t)
    Iterators.flatten((
        node_pressure_indices(m; node=node1, t=t),
        node_pressure_indices(m; node=node2, t=t)
    ))
end
