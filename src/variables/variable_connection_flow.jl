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
    connection_flow_indices(
        connection=anything,
        node=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `connection_flow` variable.
The keyword arguments act as filters for each dimension.
"""
function connection_flow_indices(;connection=anything, node=anything, direction=anything, stochastic_scenario=anything, t=anything)
    node = expand_node_group(node)
    [   
        (connection=conn, node=n, direction=d, stochastic_scenario=s, t=t)
        for (conn, n, d, s, t) in connection_flow_indices_rc(
            connection=connection,
            node=node,
            direction=direction,
            stochastic_scenario=stochastic_scenario,
            t=t,
            _compact=false
        )
    ]
end

function add_variable_connection_flow!(m::Model)
    add_variable!(
        m, 
        :connection_flow, 
        connection_flow_indices; 
        lb=x -> 0, 
        fix_value=x -> fix_connection_flow(
            connection=x.connection, node=x.node, direction=x.direction, t=x.t, _strict=false
        )
    )
end
