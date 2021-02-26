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
    connection_intact_flow_indices(
        connection=anything,
        node=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `connection_intact_flow` variable.
The keyword arguments act as filters for each dimension.
"""
function connection_intact_flow_indices(
    m::Model;
    connection=anything,
    node=anything,
    direction=anything,
    stochastic_scenario=anything,
    t=anything,
)
    node = members(node)
    [
        (connection=conn, node=n, direction=d, stochastic_scenario=s, t=t)
        for
        (conn, n, d, tb) in connection__node__direction__temporal_block(
            connection=connection,
            node=node,
            direction=direction,
            _compact=false,
        ) #if has_ptdf(connection=conn) == true
        for
        (n, s, t) in
        node_stochastic_time_indices(m; node=n, stochastic_scenario=stochastic_scenario, temporal_block=tb, t=t)
    ]
end

"""
    add_variable_connection_intact_flow!(m::Model)

Add `connection_intact_flow` variables to model `m`.
"""
function add_variable_connection_intact_flow!(m::Model)
    t0 = startref(current_window(m))
    add_variable!(
        m,
        :connection_intact_flow,
        connection_intact_flow_indices;
        lb=x -> 0,
        fix_value=x -> fix_connection_intact_flow(
            connection=x.connection,
            node=x.node,
            direction=x.direction,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
    )
end
